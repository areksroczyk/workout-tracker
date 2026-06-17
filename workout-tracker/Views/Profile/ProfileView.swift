import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showingLogoutConfirmation = false
    @State private var user: UserDTO?

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 16) {
                        if let avatarUrl = user?.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.gray)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user?.name ?? authManager.currentUser?.name ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(user?.email ?? authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Account section
                Section("Account") {
                    if let createdAt = user?.createdAt {
                        HStack {
                            Text("Member since")
                            Spacer()
                            Text(DateFormatters.displayDate.string(from: createdAt))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // App info section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out?", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("You will need to sign in again to access your data.")
            }
            .task {
                await fetchProfile()
            }
        }
    }

    private func fetchProfile() async {
        do {
            user = try await APIClient.shared.request(Endpoints.me)
        } catch {
            // Use cached data from auth manager
        }
    }
}
