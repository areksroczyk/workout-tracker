import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [ExerciseLocal]
    let session: SessionDraft

    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Duration", value: DateFormatters.formatDuration(session.duration ?? 0))
                    StatCard(title: "Exercises", value: "\(session.exercises.count)")
                    StatCard(title: "Sets", value: "\(session.totalSets)")
                    StatCard(title: "Volume", value: "\(session.totalVolume) kg")
                }
                .padding(.horizontal)

                // Notes
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(session.sortedExercises, id: \.id) { sessionExercise in
                        let name = exercises.first(where: { $0.id == sessionExercise.exerciseId })?.name ?? "Unknown"
                        VStack(alignment: .leading, spacing: 8) {
                            Text(name)
                                .font(.headline)

                            ForEach(sessionExercise.sortedSets, id: \.id) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(set.weightKg) kg")
                                    Text("x")
                                        .foregroundStyle(.secondary)
                                    Text("\(set.reps) reps")
                                    if set.completed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle(DateFormatters.displayDate.string(from: session.startedAt))
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Session?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let repo = SessionRepository(modelContext: modelContext)
                    try? await repo.deleteSession(id: session.id)
                    dismiss()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
