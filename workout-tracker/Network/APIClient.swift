import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session = URLSession.shared
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable>(_ endpoint: Endpoint, auth: Bool = true) async throws -> T {
        let urlRequest = try buildRequest(endpoint, auth: auth)
        let (data, response) = try await performRequest(urlRequest, endpoint: endpoint, auth: auth)
        try validateResponse(response)
        return try decodeResponse(data)
    }

    func requestVoid(_ endpoint: Endpoint, auth: Bool = true) async throws {
        let urlRequest = try buildRequest(endpoint, auth: auth)
        let (_, response) = try await performRequest(urlRequest, endpoint: endpoint, auth: auth)
        try validateResponse(response)
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: Endpoint, auth: Bool) throws -> URLRequest {
        var components = URLComponents(string: AppEnvironment.baseURL + endpoint.path)!
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw APIError.badRequest("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func performRequest(
        _ request: URLRequest,
        endpoint: Endpoint,
        auth: Bool
    ) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            // Handle 401 by attempting token refresh once
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401,
               auth {
                let refreshed = await attemptTokenRefresh()
                if refreshed {
                    var retryRequest = request
                    if let newToken = KeychainService.shared.getToken() {
                        retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    }
                    return try await session.data(for: retryRequest)
                }
            }

            return (data, response)
        } catch let error as URLError {
            throw APIError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 400, 422:
            throw APIError.badRequest("Invalid request")
        default:
            throw APIError.serverError
        }
    }

    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func attemptTokenRefresh() async -> Bool {
        do {
            let response: TokenResponse = try await request(Endpoints.refreshToken, auth: true)
            KeychainService.shared.saveToken(response.accessToken)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}
