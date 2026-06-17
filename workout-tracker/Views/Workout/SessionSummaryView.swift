import SwiftUI
import SwiftData

struct SessionSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseLocal]
    let session: SessionDraft
    let onDone: () -> Void

    @State private var showingSaveAsTemplate = false
    @State private var templateName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)

                        Text("Workout Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Duration", value: DateFormatters.formatDuration(session.duration ?? 0))
                        StatCard(title: "Exercises", value: "\(session.exercises.count)")
                        StatCard(title: "Sets", value: "\(session.totalSets)")
                        StatCard(title: "Volume", value: "\(session.totalVolume) kg")
                    }
                    .padding(.horizontal)

                    // Exercise breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Breakdown")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach(session.sortedExercises, id: \.id) { sessionExercise in
                            let name = exercises.first(where: { $0.id == sessionExercise.exerciseId })?.name ?? "Unknown"
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.headline)
                                ForEach(sessionExercise.sortedSets, id: \.id) { set in
                                    HStack {
                                        Text("Set \(set.setNumber)")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(set.weightKg) kg x \(set.reps)")
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

                    // Save as template (for ad-hoc sessions)
                    if session.templateId == nil {
                        Button {
                            showingSaveAsTemplate = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save as Template")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    // Done button
                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Save as Template", isPresented: $showingSaveAsTemplate) {
                TextField("Template Name", text: $templateName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { saveAsTemplate() }
            } message: {
                Text("Give your workout template a name.")
            }
        }
    }

    private func saveAsTemplate() {
        guard !templateName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let repo = TemplateRepository(modelContext: modelContext)
        let exerciseIds = session.sortedExercises.map { ($0.exerciseId, $0.orderIndex) }
        Task {
            _ = try? await repo.createTemplate(name: templateName, exerciseIds: exerciseIds)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
