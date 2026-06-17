import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncManager: SyncManager?

    var body: some View {
        TabView {
            Tab("Workout", systemImage: "dumbbell.fill") {
                WorkoutHomeView()
            }

            Tab("History", systemImage: "clock.fill") {
                HistoryListView()
            }

            Tab("Analytics", systemImage: "chart.bar.fill") {
                AnalyticsPlaceholderView()
            }

            Tab("Profile", systemImage: "person.circle.fill") {
                ProfileView()
            }
        }
        .tint(.blue)
        .task {
            let manager = SyncManager(modelContext: modelContext)
            syncManager = manager
            await manager.processQueue()
        }
    }
}
