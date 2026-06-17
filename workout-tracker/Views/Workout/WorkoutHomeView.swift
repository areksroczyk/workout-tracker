import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TemplateLocal.updatedAt, order: .reverse) private var templates: [TemplateLocal]
    @State private var showingNewSession = false
    @State private var showingCreateTemplate = false
    @State private var exerciseRepository: ExerciseRepository?
    @State private var templateRepository: TemplateRepository?
    @State private var resumeSession: SessionDraft?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Resume in-progress session banner
                    if let session = resumeSession {
                        ResumeSessionBanner(session: session) {
                            showingNewSession = true
                        }
                    }

                    // New Workout button
                    Button {
                        startNewSession(templateId: nil)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    // Templates section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Templates")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button {
                                showingCreateTemplate = true
                            } label: {
                                Image(systemName: "plus")
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal)

                        if templates.isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "No Templates Yet",
                                subtitle: "Create a workout template to quickly start your sessions."
                            )
                            .padding(.top, 32)
                        } else {
                            ForEach(templates) { template in
                                NavigationLink(value: template) {
                                    TemplateCardView(template: template)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Workout")
            .navigationDestination(for: TemplateLocal.self) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingCreateTemplate) {
                TemplateFormView(mode: .create)
            }
            .fullScreenCover(isPresented: $showingNewSession) {
                ActiveSessionView()
            }
            .refreshable {
                await refreshData()
            }
            .task {
                exerciseRepository = ExerciseRepository(modelContext: modelContext)
                templateRepository = TemplateRepository(modelContext: modelContext)
                checkForInProgressSession()
                await refreshData()
            }
        }
    }

    private func startNewSession(templateId: UUID?) {
        showingNewSession = true
    }

    private func refreshData() async {
        try? await exerciseRepository?.fetchAndCacheExercises()
        try? await templateRepository?.fetchAndCacheTemplates()
    }

    private func checkForInProgressSession() {
        let repo = SessionRepository(modelContext: modelContext)
        resumeSession = try? repo.getInProgressSession()
    }
}

struct ResumeSessionBanner: View {
    let session: SessionDraft
    let onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in Progress")
                        .fontWeight(.semibold)
                    Text("Started \(DateFormatters.displayTime.string(from: session.startedAt))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Text("Resume")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.orange.gradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal)
    }
}

struct TemplateCardView: View {
    let template: TemplateLocal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                Text("\(template.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
