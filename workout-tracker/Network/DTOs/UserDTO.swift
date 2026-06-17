import Foundation

struct UserDTO: Decodable {
    let id: UUID
    let email: String
    let name: String?
    let avatarUrl: String?
    let createdAt: Date
}

struct UserUpdateDTO: Encodable {
    let name: String?
}
