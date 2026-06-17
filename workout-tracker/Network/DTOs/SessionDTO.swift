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

    enum CodingKeys: String, CodingKey {
        case id, setNumber, weightKg, reps, completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setNumber = try container.decode(Int.self, forKey: .setNumber)
        reps = try container.decode(Int.self, forKey: .reps)
        completed = try container.decode(Bool.self, forKey: .completed)
        weightKg = try Self.decodeDecimal(from: container, forKey: .weightKg)
    }

    private static func decodeDecimal(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Decimal {
        if let string = try? container.decode(String.self, forKey: key),
           let value = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) {
            return value
        }
        if let double = try? container.decode(Double.self, forKey: key) {
            return Decimal(double)
        }
        if let int = try? container.decode(Int.self, forKey: key) {
            return Decimal(int)
        }
        throw DecodingError.typeMismatch(
            Decimal.self,
            DecodingError.Context(
                codingPath: container.codingPath + [key],
                debugDescription: "Expected decimal as string or number"
            )
        )
    }
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
