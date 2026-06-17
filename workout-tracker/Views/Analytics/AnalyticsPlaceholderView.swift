import SwiftUI
import SwiftData

struct AnalyticsPlaceholderView: View {
    @Query(
        filter: #Predicate<SessionDraft> { $0.finishedAt != nil }
    ) private var completedSessions: [SessionDraft]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick stats
                    if !completedSessions.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Total Workouts", value: "\(completedSessions.count)")
                            StatCard(title: "Total Volume", value: "\(totalVolume) kg")
                            StatCard(title: "This Week", value: "\(thisWeekCount)")
                            StatCard(title: "Avg Duration", value: averageDuration)
                        }
                        .padding(.horizontal)
                    }

                    // Coming soon
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue.opacity(0.6))

                        Text("Detailed Analytics Coming Soon")
                            .font(.headline)

                        Text("Progress charts, personal records, and more will be available in a future update.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .padding(.top, completedSessions.isEmpty ? 80 : 20)
                }
                .padding(.top)
            }
            .navigationTitle("Analytics")
        }
    }

    private var totalVolume: Decimal {
        completedSessions.reduce(Decimal.zero) { $0 + $1.totalVolume }
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return completedSessions.filter { $0.startedAt >= startOfWeek }.count
    }

    private var averageDuration: String {
        guard !completedSessions.isEmpty else { return "0m" }
        let total = completedSessions.compactMap(\.duration).reduce(0, +)
        let avg = total / Double(completedSessions.count)
        return DateFormatters.formatDuration(avg)
    }
}
