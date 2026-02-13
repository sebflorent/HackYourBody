import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<WorkoutProgram> { $0.isActive },
           sort: \WorkoutProgram.createdAt, order: .reverse)
    private var activePrograms: [WorkoutProgram]
    @Query(sort: \WorkoutProgram.createdAt, order: .reverse)
    private var allPrograms: [WorkoutProgram]

    @State private var vm = WorkoutViewModel()
    @State private var showProgramHistory = false

    private var profile: UserProfile? { profiles.first }
    private var activeProgram: WorkoutProgram? { activePrograms.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let program = activeProgram {
                        activeProgramSection(program)
                    } else {
                        noProgramSection
                    }
                }
                .padding()
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task { await generateNewProgram() }
                        } label: {
                            Label("Nouveau programme IA", systemImage: "sparkles")
                        }

                        if allPrograms.count > 1 {
                            Button {
                                showProgramHistory = true
                            } label: {
                                Label("Historique", systemImage: "clock")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showProgramHistory) {
                ProgramHistoryView(programs: allPrograms)
            }
            .overlay {
                if vm.isGenerating {
                    generatingOverlay
                }
            }
            .alert("Erreur", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - No Program

    private var noProgramSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Pas de programme actif")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Génère un programme personnalisé avec l'IA basé sur ton profil")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await generateNewProgram() }
            } label: {
                Label("Générer mon programme", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Active Program

    private func activeProgramSection(_ program: WorkoutProgram) -> some View {
        VStack(spacing: 16) {
            // Program header
            ProgramHeaderCard(program: program)

            // Sessions list
            VStack(alignment: .leading, spacing: 12) {
                Text("Séances")
                    .font(.headline)

                ForEach(program.sessions.sorted { $0.dayNumber < $1.dayNumber }) { session in
                    NavigationLink {
                        SessionDetailView(session: session, vm: vm)
                    } label: {
                        SessionRow(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("L'IA génère ton programme...")
                    .font(.headline)
                Text("Cela peut prendre quelques secondes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private func generateNewProgram() async {
        guard let profile else { return }
        await vm.generateProgram(profile: profile, modelContext: modelContext)
    }
}

// MARK: - Program Header Card

struct ProgramHeaderCard: View {
    let program: WorkoutProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(program.splitType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: program.splitType.icon)
                    .font(.title)
                    .foregroundStyle(.blue)
            }

            if !program.programDescription.isEmpty {
                Text(program.programDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Semaine \(program.currentWeek)/\(program.durationWeeks)", systemImage: "calendar")
                Spacer()
                Label("\(program.completedSessions)/\(program.totalSessions) séances", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ProgressView(value: program.progressPercentage)
                .tint(.blue)
        }
        .cardStyle()
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(session.isCompleted ? .green.opacity(0.15) : .blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                if session.isCompleted {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                } else {
                    Text("J\(session.dayNumber)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text("\(session.exercises.count) exercices - \(session.muscleGroupsDisplay)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Program History

struct ProgramHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let programs: [WorkoutProgram]

    var body: some View {
        NavigationStack {
            List(programs) { program in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(program.name)
                            .fontWeight(.medium)
                        if program.isActive {
                            Text("ACTIF")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(program.completedSessions)/\(program.totalSessions) séances - \(program.createdAt.shortFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Historique programmes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
