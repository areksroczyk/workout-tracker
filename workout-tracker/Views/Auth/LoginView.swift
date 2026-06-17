import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Liftd")
                    .font(.system(size: 42, weight: .black))
                    .tracking(-0.5)

                Text("Your workout journal")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    signIn()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authManager.isLoading)
                .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 48)
        }
    }

    private func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        Task {
            await authManager.signInWithGoogle(presenting: rootVC)
        }
    }
}
