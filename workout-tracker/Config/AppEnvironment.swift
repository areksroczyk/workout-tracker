import Foundation

enum AppEnvironment {
    #if DEBUG
    static let baseURL = "http://localhost:8000/api/v1"
    #else
    static let baseURL = "https://liftd-api.railway.app/api/v1"
    #endif

    static let isAnalyticsEnabled = false
}
