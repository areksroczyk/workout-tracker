import Foundation
import SwiftData

@Model
final class SessionExerciseDraft {
    var id: UUID
    var exerciseId: UUID
    var orderIndex: Int
    var session: SessionDraft?
    @Relationship(deleteRule: .cascade, inverse: \SetDraft.sessionExercise)
    var sets: [SetDraft]

    init(id: UUID = UUID(), exerciseId: UUID, orderIndex: Int, sets: [SetDraft] = []) {
        self.id = id
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.sets = sets
    }

    var sortedSets: [SetDraft] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }
}
