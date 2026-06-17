import Foundation
import SwiftData

@Model
final class SessionDraft {
    @Attribute(.unique) var id: UUID
    var templateId: UUID?
    var startedAt: Date
    var finishedAt: Date?
    var notes: String?
    var isSynced: Bool
    @Relationship(deleteRule: .cascade, inverse: \SessionExerciseDraft.session)
    var exercises: [SessionExerciseDraft]

    init(
        id: UUID = UUID(),
        templateId: UUID? = nil,
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        notes: String? = nil,
        isSynced: Bool = false,
        exercises: [SessionExerciseDraft] = []
    ) {
        self.id = id
        self.templateId = templateId
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.notes = notes
        self.isSynced = isSynced
        self.exercises = exercises
    }

    var sortedExercises: [SessionExerciseDraft] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var duration: TimeInterval? {
        guard let finishedAt else { return nil }
        return finishedAt.timeIntervalSince(startedAt)
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.completed).count }
    }

    var totalVolume: Decimal {
        exercises.reduce(Decimal.zero) { total, exercise in
            total + exercise.sets.filter(\.completed).reduce(Decimal.zero) { $0 + $1.weightKg * Decimal($1.reps) }
        }
    }
}
