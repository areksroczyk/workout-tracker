import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case badRequest(String)
    case serverError
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .badRequest(let message):
            return message
        case .serverError:
            return "Something went wrong on the server. Please try again later."
        case .networkError:
            return "No internet connection. Your data is saved locally."
        case .decodingError:
            return "Failed to process the server response."
        }
    }
}
