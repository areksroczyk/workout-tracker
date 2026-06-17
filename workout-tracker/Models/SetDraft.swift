import Foundation
import SwiftData

@Model
final class SetDraft {
    var id: UUID
    var setNumber: Int
    var weightKg: Decimal
    var reps: Int
    var completed: Bool
    var sessionExercise: SessionExerciseDraft?

    init(id: UUID = UUID(), setNumber: Int, weightKg: Decimal = 0, reps: Int = 0, completed: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.completed = completed
    }
}
