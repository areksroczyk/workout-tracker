import SwiftUI
import SwiftData
import Combine

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [ExerciseLocal]

    var templateId: UUID? = nil

    @State private var session: SessionDraft?
    @State private var elapsedTime: TimeInterval = 0
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirmation = false
    @State private var showingSummary = false
    @State private var restTimerSeconds = 0
    @State private var isRestTimerActive = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if let session {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Elapsed timer
                            Text(DateFormatters.formatElapsed(elapsedTime))
                                .font(.system(.title2, design: .monospaced))
                                .foregroundStyle(.secondary)

                            // Exercises
                            ForEach(session.sortedExercises, id: \.id) { sessionExercise in
                                SessionExerciseCard(
                                    sessionExercise: sessionExercise,
                                    exerciseName: exercises.first(where: { $0.id == sessionExercise.exerciseId })?.name ?? "Unknown",
                                    onSetCompleted: { startRestTimer() },
                                    onChanged: { saveSession() }
                                )
                            }

                            // Add Exercise button
                            Button {
                                showingExercisePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)

                            Spacer(minLength: 100)
                        }
                        .padding(.top)
                    }
                } else {
                    ProgressView()
                }

                // Rest Timer overlay
                if isRestTimerActive {
                    RestTimerView(seconds: restTimerSeconds) {
                        isRestTimerActive = false
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                }
            }
            .alert("Finish Workout?", isPresented: $showingFinishConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Finish") { finishWorkout() }
            } message: {
                Text("This will save your workout session.")
            }
            .fullScreenCover(isPresented: $showingSummary) {
                if let session {
                    SessionSummaryView(session: session) {
                        dismiss()
                    }
                }
            }
            .onReceive(timer) { _ in
                if let session {
                    elapsedTime = Date.now.timeIntervalSince(session.startedAt)
                }
                if isRestTimerActive {
                    if restTimerSeconds > 0 {
                        restTimerSeconds -= 1
                    } else {
                        isRestTimerActive = false
                    }
                }
            }
            .task {
                initializeSession()
            }
        }
    }

    private func initializeSession() {
        // Check for existing in-progress session
        let repo = SessionRepository(modelContext: modelContext)
        if let existing = try? repo.getInProgressSession() {
            session = existing
            return
        }

        // Create new session
        let newSession = SessionDraft(templateId: templateId)
        modelContext.insert(newSession)

        // Pre-populate from template if provided
        if let templateId {
            let descriptor = FetchDescriptor<TemplateLocal>(predicate: #Predicate { $0.id == templateId })
            if let template = try? modelContext.fetch(descriptor).first {
                for te in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                    let exerciseDraft = SessionExerciseDraft(
                        exerciseId: te.exerciseId,
                        orderIndex: te.orderIndex
                    )
                    exerciseDraft.session = newSession
                    modelContext.insert(exerciseDraft)

                    // Add one empty set
                    let set = SetDraft(setNumber: 1)
                    set.sessionExercise = exerciseDraft
                    modelContext.insert(set)
                }
            }
        }

        try? modelContext.save()
        session = newSession
    }

    private func addExercise(_ exercise: ExerciseLocal) {
        guard let session else { return }
        let orderIndex = session.exercises.count
        let exerciseDraft = SessionExerciseDraft(
            exerciseId: exercise.id,
            orderIndex: orderIndex
        )
        exerciseDraft.session = session
        modelContext.insert(exerciseDraft)

        let set = SetDraft(setNumber: 1)
        set.sessionExercise = exerciseDraft
        modelContext.insert(set)

        saveSession()
    }

    private func startRestTimer() {
        restTimerSeconds = 90
        isRestTimerActive = true
    }

    private func saveSession() {
        try? modelContext.save()
    }

    private func finishWorkout() {
        guard let session else { return }
        session.finishedAt = .now
        saveSession()

        Task {
            let repo = SessionRepository(modelContext: modelContext)
            try? await repo.saveCompletedSession(session)
        }

        showingSummary = true
    }
}

struct SessionExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    let sessionExercise: SessionExerciseDraft
    let exerciseName: String
    let onSetCompleted: () -> Void
    let onChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.headline)
                .padding(.horizontal)

            // Header row
            HStack {
                Text("Set")
                    .frame(width: 36)
                Text("kg")
                    .frame(maxWidth: .infinity)
                Text("Reps")
                    .frame(maxWidth: .infinity)
                Image(systemName: "checkmark")
                    .frame(width: 44)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

            // Set rows
            ForEach(sessionExercise.sortedSets, id: \.id) { set in
                SetRowView(set: set, onCompleted: onSetCompleted, onChanged: onChanged)
            }

            // Add set button
            Button {
                let newSetNumber = (sessionExercise.sets.map(\.setNumber).max() ?? 0) + 1
                let newSet = SetDraft(setNumber: newSetNumber)
                newSet.sessionExercise = sessionExercise
                modelContext.insert(newSet)
                onChanged()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
