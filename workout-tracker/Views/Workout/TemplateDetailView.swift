import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let template: TemplateLocal
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var showingActiveSession = false
    @Query private var exercises: [ExerciseLocal]

    var sortedExercises: [TemplateExerciseLocal] {
        template.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Start Workout button
                Button {
                    showingActiveSession = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                // Exercises list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if sortedExercises.isEmpty {
                        Text("No exercises added yet.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(sortedExercises, id: \.id) { templateExercise in
                            if let exercise = exercises.first(where: { $0.id == templateExercise.exerciseId }) {
                                ExerciseCardView(exercise: exercise)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            TemplateFormView(mode: .edit(template))
        }
        .fullScreenCover(isPresented: $showingActiveSession) {
            ActiveSessionView(templateId: template.id)
        }
        .alert("Delete Template?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let repo = TemplateRepository(modelContext: modelContext)
                    try? await repo.deleteTemplate(id: template.id)
                    dismiss()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct ExerciseCardView: View {
    let exercise: ExerciseLocal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(exercise.category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
