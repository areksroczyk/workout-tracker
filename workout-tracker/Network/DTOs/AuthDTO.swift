import Foundation

struct AuthGoogleRequest: Encodable {
    let googleIdToken: String
}

struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let user: UserBasicDTO
}

struct UserBasicDTO: Decodable {
    let id: UUID
    let email: String
    let name: String?
}
