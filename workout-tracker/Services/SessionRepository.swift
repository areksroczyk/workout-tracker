import Foundation
import SwiftData

@Observable
final class SessionRepository {
    private let apiClient = APIClient.shared
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveCompletedSession(_ draft: SessionDraft) async throws {
        guard let finishedAt = draft.finishedAt else { return }

        let dto = SessionCreateDTO(
            startedAt: draft.startedAt,
            finishedAt: finishedAt,
            templateId: draft.templateId,
            notes: draft.notes,
            exercises: draft.sortedExercises.map { exercise in
                SessionExerciseCreateDTO(
                    exerciseId: exercise.exerciseId,
                    orderIndex: exercise.orderIndex,
                    sets: exercise.sortedSets.map { set in
                        SetCreateDTO(
                            setNumber: set.setNumber,
                            weightKg: set.weightKg,
                            reps: set.reps,
                            completed: set.completed
                        )
                    }
                )
            }
        )

        if NetworkMonitor.shared.isConnected {
            let _: SessionDTO = try await apiClient.request(Endpoints.createSession(dto))
            draft.isSynced = true
            try modelContext.save()
        } else {
            draft.isSynced = false
            let payload = try JSONEncoder().encode(dto)
            let queueItem = SyncQueueItem(operationType: "create_session", entityId: draft.id, payload: payload)
            modelContext.insert(queueItem)
            try modelContext.save()
        }
    }

    func fetchHistory() async throws {
        let dtos: [SessionListDTO] = try await apiClient.request(Endpoints.sessions())

        var details: [SessionDTO] = []
        for listItem in dtos {
            let detail: SessionDTO = try await apiClient.request(Endpoints.session(id: listItem.id))
            details.append(detail)
        }

        // Replace synced history only after all server sessions are fetched successfully
        let allLocal = try modelContext.fetch(FetchDescriptor<SessionDraft>())
        for local in allLocal where local.finishedAt != nil && local.isSynced {
            modelContext.delete(local)
        }

        for detail in details {
            try insertSessionFromServer(detail)
        }

        try modelContext.save()
    }

    private func insertSessionFromServer(_ detail: SessionDTO) throws {
        let sessionId = detail.id
        let existingDescriptor = FetchDescriptor<SessionDraft>(
            predicate: #Predicate { $0.id == sessionId }
        )
        if let existing = try modelContext.fetch(existingDescriptor).first {
            modelContext.delete(existing)
        }

        let draft = SessionDraft(
            id: detail.id,
            templateId: detail.templateId,
            startedAt: detail.startedAt,
            finishedAt: detail.finishedAt,
            notes: detail.notes,
            isSynced: true
        )
        modelContext.insert(draft)

        for ex in detail.exercises {
            let exerciseDraft = SessionExerciseDraft(
                exerciseId: ex.exerciseId,
                orderIndex: ex.orderIndex
            )
            exerciseDraft.session = draft
            modelContext.insert(exerciseDraft)

            for s in ex.sets {
                let setDraft = SetDraft(
                    setNumber: s.setNumber,
                    weightKg: s.weightKg,
                    reps: s.reps,
                    completed: s.completed
                )
                setDraft.sessionExercise = exerciseDraft
                modelContext.insert(setDraft)
            }
        }
    }

    func getCachedHistory() throws -> [SessionDraft] {
        var descriptor = FetchDescriptor<SessionDraft>(
            predicate: #Predicate { $0.finishedAt != nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteSession(id: UUID) async throws {
        let descriptor = FetchDescriptor<SessionDraft>(predicate: #Predicate { $0.id == id })
        if let session = try modelContext.fetch(descriptor).first {
            modelContext.delete(session)
            try modelContext.save()
        }

        if NetworkMonitor.shared.isConnected {
            try await apiClient.requestVoid(Endpoints.deleteSession(id: id))
        }
    }

    func getInProgressSession() throws -> SessionDraft? {
        let descriptor = FetchDescriptor<SessionDraft>(
            predicate: #Predicate { $0.finishedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }
}
