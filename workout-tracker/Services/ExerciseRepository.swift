import Foundation
import SwiftData

@Observable
final class ExerciseRepository {
    private let apiClient = APIClient.shared
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAndCacheExercises() async throws {
        let dtos: [ExerciseDTO] = try await apiClient.request(Endpoints.exercises())

        for dto in dtos {
            let descriptor = FetchDescriptor<ExerciseLocal>(
                predicate: #Predicate { $0.id == dto.id }
            )
            let existing = try modelContext.fetch(descriptor)

            if let exercise = existing.first {
                exercise.name = dto.name
                exercise.category = dto.category
                exercise.exerciseDescription = dto.description
                exercise.muscleGroups = dto.muscleGroups ?? []
            } else {
                let exercise = ExerciseLocal(
                    id: dto.id,
                    name: dto.name,
                    category: dto.category,
                    exerciseDescription: dto.description,
                    muscleGroups: dto.muscleGroups ?? []
                )
                modelContext.insert(exercise)
            }
        }

        try modelContext.save()
    }

    func getCachedExercises(category: String? = nil, search: String? = nil) throws -> [ExerciseLocal] {
        var descriptor = FetchDescriptor<ExerciseLocal>(sortBy: [SortDescriptor(\.name)])

        if let category, let search {
            descriptor.predicate = #Predicate {
                $0.category == category && $0.name.localizedStandardContains(search)
            }
        } else if let category {
            descriptor.predicate = #Predicate { $0.category == category }
        } else if let search {
            descriptor.predicate = #Predicate { $0.name.localizedStandardContains(search) }
        }

        return try modelContext.fetch(descriptor)
    }
}
