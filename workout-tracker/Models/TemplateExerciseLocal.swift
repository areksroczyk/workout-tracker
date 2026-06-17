import Foundation
import SwiftData

@Model
final class TemplateExerciseLocal {
    var id: UUID
    var exerciseId: UUID
    var orderIndex: Int
    var template: TemplateLocal?

    init(id: UUID = UUID(), exerciseId: UUID, orderIndex: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
    }
}
