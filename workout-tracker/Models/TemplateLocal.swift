import Foundation
import SwiftData

@Model
final class TemplateLocal {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \TemplateExerciseLocal.template)
    var exercises: [TemplateExerciseLocal]

    init(id: UUID, name: String, createdAt: Date = .now, updatedAt: Date = .now, exercises: [TemplateExerciseLocal] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.exercises = exercises
    }
}
