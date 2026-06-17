import Foundation

struct ExerciseDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let description: String?
    let muscleGroups: [String]?
}
