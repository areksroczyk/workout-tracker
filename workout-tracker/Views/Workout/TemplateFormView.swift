import SwiftUI
import SwiftData

enum TemplateFormMode {
    case create
    case edit(TemplateLocal)
}

struct TemplateFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let mode: TemplateFormMode

    @State private var name = ""
    @State private var selectedExercises: [(ExerciseLocal, Int)] = []
    @State private var showingExercisePicker = false
    @State private var isSaving = false

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("e.g., Push Day", text: $name)
                }

                Section {
                    if selectedExercises.isEmpty {
                        Text("No exercises added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(selectedExercises.enumerated()), id: \.element.0.id) { index, pair in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(pair.0.name)
                                        .font(.headline)
                                    Text(pair.0.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            selectedExercises.remove(atOffsets: indexSet)
                            reindex()
                        }
                        .onMove { from, to in
                            selectedExercises.move(fromOffsets: from, toOffset: to)
                            reindex()
                        }
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    selectedExercises.append((exercise, selectedExercises.count))
                }
            }
            .onAppear {
                if case .edit(let template) = mode {
                    name = template.name
                    loadExercises(for: template)
                }
            }
        }
    }

    private func loadExercises(for template: TemplateLocal) {
        let sorted = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
        let repo = ExerciseRepository(modelContext: modelContext)
        let allExercises = (try? repo.getCachedExercises()) ?? []

        selectedExercises = sorted.compactMap { te in
            guard let exercise = allExercises.first(where: { $0.id == te.exerciseId }) else { return nil }
            return (exercise, te.orderIndex)
        }
    }

    private func reindex() {
        selectedExercises = selectedExercises.enumerated().map { ($1.0, $0) }
    }

    private func save() {
        isSaving = true
        let repo = TemplateRepository(modelContext: modelContext)
        let exerciseIds = selectedExercises.map { ($0.0.id, $0.1) }

        Task {
            do {
                switch mode {
                case .create:
                    _ = try await repo.createTemplate(name: name.trimmingCharacters(in: .whitespaces), exerciseIds: exerciseIds)
                case .edit(let template):
                    try await repo.updateTemplate(id: template.id, name: name.trimmingCharacters(in: .whitespaces), exerciseIds: exerciseIds)
                }
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
