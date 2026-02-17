import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = WorkoutViewModel()
    @State private var bestPRs: [PersonalRecord] = []
    @State private var allPRs: [PersonalRecord] = []
    @State private var selectedExercise: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if bestPRs.isEmpty {
                    ContentUnavailableView(
                        "Pas encore de records",
                        systemImage: "trophy",
                        description: Text("Tes records personnels apparaîtront ici au fur et à mesure de tes séances")
                    )
                } else {
                    // Summary stats
                    summaryCard

                    // PRs by exercise
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Records par exercice")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(bestPRs, id: \.exerciseName) { pr in
                            NavigationLink {
                                ExerciseHistoryView(exerciseName: pr.exerciseName)
                            } label: {
                                prRow(pr)
                            }
                        }
                    }

                    // Recent PRs timeline
                    if allPRs.count > bestPRs.count {
                        recentPRsSection
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Records personnels")
        .onAppear {
            bestPRs = vm.allExerciseBestPRs(modelContext: modelContext)
            allPRs = vm.personalRecords(modelContext: modelContext)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 24) {
            VStack {
                Text("\(bestPRs.count)")
                    .font(.title.bold())
                    .foregroundStyle(.yellow)
                Text("exercices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                let bestE1RM = bestPRs.max(by: { $0.estimated1RM < $1.estimated1RM })
                Text(bestE1RM?.estimated1RM.cleanString ?? "0")
                    .font(.title.bold())
                    .foregroundStyle(.purple)
                Text("meilleur 1RM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                let totalPRs = allPRs.count
                Text("\(totalPRs)")
                    .font(.title.bold())
                    .foregroundStyle(.blue)
                Text("total PRs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - PR Row

    private func prRow(_ pr: PersonalRecord) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(pr.date.shortFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(pr.weightKg.cleanString) kg x \(pr.reps)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("1RM: \(pr.estimated1RM.cleanString) kg")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Recent PRs Timeline

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Derniers records")
                .font(.headline)
                .padding(.horizontal)

            ForEach(Array(allPRs.prefix(10).enumerated()), id: \.offset) { _, pr in
                HStack(spacing: 12) {
                    VStack {
                        Circle()
                            .fill(prTypeColor(pr.recordType))
                            .frame(width: 10, height: 10)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(pr.exerciseName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text(pr.date.shortFormatted)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text(pr.recordType.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(prTypeColor(pr.recordType).opacity(0.15))
                                .foregroundStyle(prTypeColor(pr.recordType))
                                .clipShape(Capsule())

                            Text("\(pr.weightKg.cleanString) kg x \(pr.reps)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func prTypeColor(_ type: PRType) -> Color {
        switch type {
        case .maxWeight: return .blue
        case .maxReps: return .green
        case .estimated1RM: return .purple
        }
    }
}
