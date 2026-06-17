import Foundation

struct TemplateDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let exercises: [TemplateExerciseDTO]
}

struct TemplateExerciseDTO: Codable, Identifiable {
    let id: UUID
    let exerciseId: UUID
    let orderIndex: Int
    let exercise: ExerciseDTO?
}

struct TemplateCreateDTO: Codable {
    let name: String
    let exercises: [TemplateExerciseCreateDTO]
}

struct TemplateExerciseCreateDTO: Codable {
    let exerciseId: UUID
    let orderIndex: Int
}
