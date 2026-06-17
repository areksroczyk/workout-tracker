import Foundation
import UIKit
import GoogleSignIn

@Observable
final class AuthManager {
    var isAuthenticated = false
    var currentUser: UserBasicDTO?
    var isLoading = false
    var errorMessage: String?

    private let apiClient = APIClient.shared
    private let keychain = KeychainService.shared

    init() {
        NotificationCenter.default.addObserver(
            forName: .authSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.signOut()
            }
        }
    }

    func restoreSession() async {
        guard keychain.getToken() != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: TokenResponse = try await apiClient.request(Endpoints.refreshToken)
            keychain.saveToken(response.accessToken)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            signOut()
        }
    }

    @MainActor
    func signInWithGoogle(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                return
            }

            let response: TokenResponse = try await apiClient.request(
                Endpoints.googleAuth(idToken: idToken),
                auth: false
            )

            keychain.saveToken(response.accessToken)
            currentUser = response.user
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Sign in failed. Please try again."
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        keychain.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }
}
