import Foundation
import SwiftData

@Observable
final class TemplateRepository {
    private let apiClient = APIClient.shared
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAndCacheTemplates() async throws {
        let dtos: [TemplateDTO] = try await apiClient.request(Endpoints.templates)

        // Clear existing templates and re-insert from server
        let existing = try modelContext.fetch(FetchDescriptor<TemplateLocal>())
        for template in existing {
            modelContext.delete(template)
        }

        for dto in dtos {
            let template = TemplateLocal(
                id: dto.id,
                name: dto.name,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
            modelContext.insert(template)

            for exerciseDTO in dto.exercises {
                let te = TemplateExerciseLocal(
                    id: exerciseDTO.id,
                    exerciseId: exerciseDTO.exerciseId,
                    orderIndex: exerciseDTO.orderIndex
                )
                te.template = template
                modelContext.insert(te)
            }
        }

        try modelContext.save()
    }

    func getCachedTemplates() throws -> [TemplateLocal] {
        let descriptor = FetchDescriptor<TemplateLocal>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func createTemplate(name: String, exerciseIds: [(UUID, Int)]) async throws -> TemplateDTO {
        let dto = TemplateCreateDTO(
            name: name,
            exercises: exerciseIds.map { TemplateExerciseCreateDTO(exerciseId: $0.0, orderIndex: $0.1) }
        )

        if NetworkMonitor.shared.isConnected {
            let response: TemplateDTO = try await apiClient.request(Endpoints.createTemplate(dto))
            // Cache locally
            let template = TemplateLocal(id: response.id, name: response.name, createdAt: response.createdAt, updatedAt: response.updatedAt)
            modelContext.insert(template)
            for ex in response.exercises {
                let te = TemplateExerciseLocal(id: ex.id, exerciseId: ex.exerciseId, orderIndex: ex.orderIndex)
                te.template = template
                modelContext.insert(te)
            }
            try modelContext.save()
            return response
        } else {
            // Save locally and queue for sync
            let localId = UUID()
            let template = TemplateLocal(id: localId, name: name)
            modelContext.insert(template)
            for (exerciseId, order) in exerciseIds {
                let te = TemplateExerciseLocal(exerciseId: exerciseId, orderIndex: order)
                te.template = template
                modelContext.insert(te)
            }

            let payload = try JSONEncoder().encode(dto)
            let queueItem = SyncQueueItem(operationType: "create_template", entityId: localId, payload: payload)
            modelContext.insert(queueItem)

            try modelContext.save()

            return TemplateDTO(
                id: localId,
                name: name,
                createdAt: .now,
                updatedAt: .now,
                exercises: exerciseIds.map { TemplateExerciseDTO(id: UUID(), exerciseId: $0.0, orderIndex: $0.1, exercise: nil) }
            )
        }
    }

    func updateTemplate(id: UUID, name: String, exerciseIds: [(UUID, Int)]) async throws {
        let dto = TemplateCreateDTO(
            name: name,
            exercises: exerciseIds.map { TemplateExerciseCreateDTO(exerciseId: $0.0, orderIndex: $0.1) }
        )

        if NetworkMonitor.shared.isConnected {
            let _: TemplateDTO = try await apiClient.request(Endpoints.updateTemplate(id: id, dto))
            try await fetchAndCacheTemplates()
        } else {
            let payload = try JSONEncoder().encode(dto)
            let queueItem = SyncQueueItem(operationType: "update_template", entityId: id, payload: payload)
            modelContext.insert(queueItem)
            try modelContext.save()
        }
    }

    func deleteTemplate(id: UUID) async throws {
        // Delete locally
        let descriptor = FetchDescriptor<TemplateLocal>(predicate: #Predicate { $0.id == id })
        if let template = try modelContext.fetch(descriptor).first {
            modelContext.delete(template)
            try modelContext.save()
        }

        if NetworkMonitor.shared.isConnected {
            try await apiClient.requestVoid(Endpoints.deleteTemplate(id: id))
        } else {
            let queueItem = SyncQueueItem(operationType: "delete_template", entityId: id, payload: Data())
            modelContext.insert(queueItem)
            try modelContext.save()
        }
    }
}
