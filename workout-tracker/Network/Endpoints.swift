import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let body: Encodable?
    let queryItems: [URLQueryItem]

    init(path: String, method: HTTPMethod = .get, body: Encodable? = nil, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
    }
}

enum Endpoints {
    // MARK: - Auth
    static func googleAuth(idToken: String) -> Endpoint {
        Endpoint(path: "/auth/google", method: .post, body: AuthGoogleRequest(googleIdToken: idToken))
    }

    static var refreshToken: Endpoint {
        Endpoint(path: "/auth/refresh", method: .post)
    }

    static var logout: Endpoint {
        Endpoint(path: "/auth/logout", method: .post)
    }

    // MARK: - Exercises
    static func exercises(category: String? = nil, search: String? = nil) -> Endpoint {
        var items: [URLQueryItem] = []
        if let category { items.append(URLQueryItem(name: "category", value: category)) }
        if let search { items.append(URLQueryItem(name: "search", value: search)) }
        return Endpoint(path: "/exercises", queryItems: items)
    }

    static func exercise(id: UUID) -> Endpoint {
        Endpoint(path: "/exercises/\(id.uuidString)")
    }

    // MARK: - Templates
    static var templates: Endpoint {
        Endpoint(path: "/templates")
    }

    static func createTemplate(_ dto: TemplateCreateDTO) -> Endpoint {
        Endpoint(path: "/templates", method: .post, body: dto)
    }

    static func template(id: UUID) -> Endpoint {
        Endpoint(path: "/templates/\(id.uuidString)")
    }

    static func updateTemplate(id: UUID, _ dto: TemplateCreateDTO) -> Endpoint {
        Endpoint(path: "/templates/\(id.uuidString)", method: .put, body: dto)
    }

    static func deleteTemplate(id: UUID) -> Endpoint {
        Endpoint(path: "/templates/\(id.uuidString)", method: .delete)
    }

    // MARK: - Sessions
    static func sessions(skip: Int = 0, limit: Int = 20) -> Endpoint {
        Endpoint(path: "/sessions", queryItems: [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ])
    }

    static func createSession(_ dto: SessionCreateDTO) -> Endpoint {
        Endpoint(path: "/sessions", method: .post, body: dto)
    }

    static func session(id: UUID) -> Endpoint {
        Endpoint(path: "/sessions/\(id.uuidString)")
    }

    static func deleteSession(id: UUID) -> Endpoint {
        Endpoint(path: "/sessions/\(id.uuidString)", method: .delete)
    }

    // MARK: - Users
    static var me: Endpoint {
        Endpoint(path: "/users/me")
    }

    static func updateMe(_ dto: UserUpdateDTO) -> Endpoint {
        Endpoint(path: "/users/me", method: .patch, body: dto)
    }

    static var deleteMe: Endpoint {
        Endpoint(path: "/users/me", method: .delete)
    }
}
