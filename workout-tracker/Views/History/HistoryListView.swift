import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SessionDraft> { $0.finishedAt != nil },
        sort: \SessionDraft.startedAt,
        order: .reverse
    ) private var sessions: [SessionDraft]
    @Query private var exercises: [ExerciseLocal]
    @Query private var templates: [TemplateLocal]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Workouts Yet",
                        subtitle: "Complete your first workout to see it here."
                    )
                } else {
                    List(sessions) { session in
                        NavigationLink(value: session) {
                            SessionRowView(
                                session: session,
                                templateName: templateName(for: session),
                                exerciseNames: exerciseNames(for: session)
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: SessionDraft.self) { session in
                SessionDetailView(session: session)
            }
            .refreshable {
                let repo = SessionRepository(modelContext: modelContext)
                try? await repo.fetchHistory()
            }
            .task {
                let repo = SessionRepository(modelContext: modelContext)
                try? await repo.fetchHistory()
            }
        }
    }

    private func templateName(for session: SessionDraft) -> String? {
        guard let templateId = session.templateId else { return nil }
        return templates.first(where: { $0.id == templateId })?.name
    }

    private func exerciseNames(for session: SessionDraft) -> [String] {
        session.sortedExercises.prefix(3).compactMap { se in
            exercises.first(where: { $0.id == se.exerciseId })?.name
        }
    }
}

struct SessionRowView: View {
    let session: SessionDraft
    let templateName: String?
    let exerciseNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(templateName ?? "Free Workout")
                    .font(.headline)
                Spacer()
                if !session.isSynced {
                    Image(systemName: "icloud.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text(DateFormatters.displayDateTime.string(from: session.startedAt))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label(DateFormatters.formatDuration(session.duration ?? 0), systemImage: "timer")
                Label("\(session.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(session.totalSets) sets", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !exerciseNames.isEmpty {
                Text(exerciseNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
