import Foundation

struct SessionDTO: Codable, Identifiable {
    let id: UUID
    let templateId: UUID?
    let startedAt: Date
    let finishedAt: Date
    let notes: String?
    let syncedAt: Date?
    let exercises: [SessionExerciseDTO]
}

struct SessionListDTO: Codable, Identifiable {
    let id: UUID
    let templateId: UUID?
    let startedAt: Date
    let finishedAt: Date
    let notes: String?
    let exerciseCount: Int
}

struct SessionExerciseDTO: Codable, Identifiable {
    let id: UUID
    let exerciseId: UUID
    let orderIndex: Int
    let exercise: ExerciseDTO?
    let sets: [SetDTO]
}

struct SetDTO: Codable, Identifiable {
    let id: UUID
    let setNumber: Int
    let weightKg: Decimal
    let reps: Int
    let completed: Bool
}

struct SessionCreateDTO: Codable {
    let startedAt: Date
    let finishedAt: Date
    let templateId: UUID?
    let notes: String?
    let exercises: [SessionExerciseCreateDTO]
}

struct SessionExerciseCreateDTO: Codable {
    let exerciseId: UUID
    let orderIndex: Int
    let sets: [SetCreateDTO]
}

struct SetCreateDTO: Codable {
    let setNumber: Int
    let weightKg: Decimal
    let reps: Int
    let completed: Bool
}
