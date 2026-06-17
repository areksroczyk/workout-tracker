import SwiftUI
import SwiftData
import UIKit
import GoogleSignIn

@main
struct workout_trackerApp: App {
    init() {
        let roundedLargeTitle = UIFont.systemFont(ofSize: 34, weight: .black, width: .standard)
            .fontDescriptor.withDesign(.rounded)!
        let roundedHeadline = UIFont.systemFont(ofSize: 17, weight: .bold, width: .standard)
            .fontDescriptor.withDesign(.rounded)!

        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(descriptor: roundedLargeTitle, size: 0),
            .kern: -0.5
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(descriptor: roundedHeadline, size: 0),
            .kern: -0.3
        ]
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExerciseLocal.self,
            TemplateLocal.self,
            TemplateExerciseLocal.self,
            SessionDraft.self,
            SessionExerciseDraft.self,
            SetDraft.self,
            SyncQueueItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await authManager.restoreSession()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("Loading...")
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}
