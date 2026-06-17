import Foundation
import SwiftData

@Model
final class ExerciseLocal {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var exerciseDescription: String?
    var muscleGroups: [String]

    init(id: UUID, name: String, category: String, exerciseDescription: String? = nil, muscleGroups: [String] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.exerciseDescription = exerciseDescription
        self.muscleGroups = muscleGroups
    }
}
