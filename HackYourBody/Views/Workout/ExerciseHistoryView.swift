import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exerciseName: String

    @State private var vm = WorkoutViewModel()
    @State private var history: [(date: Date, weight: Double, reps: Int)] = []
    @State private var detailedLogs: [SetLog] = []
    @State private var prs: [PersonalRecord] = []
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if history.isEmpty && detailedLogs.isEmpty {
                    ContentUnavailableView(
                        "Pas encore d'historique",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Les données apparaîtront après ta première séance")
                    )
                } else {
                    // PR Banner
                    if let bestPR = prs.first {
                        prBanner(bestPR)
                    }

                    // Tab picker: Charts vs Detailed
                    Picker("Vue", selection: $selectedTab) {
                        Text("Graphiques").tag(0)
                        Text("Détail séries").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        chartsSection
                    } else {
                        detailedLogsSection
                    }

                    // Stagnation analysis
                    stagnationSection

                    // AI suggestion
                    if let suggestion = vm.progressSuggestion {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Conseil IA", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(.purple)
                            Text(suggestion)
                                .font(.subheadline)
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(exerciseName)
        .onAppear {
            loadData()
        }
    }

    // MARK: - PR Banner

    private func prBanner(_ pr: PersonalRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Record personnel")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                Text("\(pr.weightKg.cleanString) kg x \(pr.reps) reps")
                    .font(.headline)
                Text("1RM estimé: \(pr.estimated1RM.cleanString) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(pr.date.shortFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Charts

    private var chartsSection: some View {
        VStack(spacing: 20) {
            // Estimated 1RM progression chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Progression 1RM estimé")
                    .font(.headline)

                Chart {
                    ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                        let e1RM = entry.reps == 1 ? entry.weight : entry.weight * (1.0 + Double(entry.reps) / 30.0)
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("1RM", e1RM)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("1RM", e1RM)
                        )
                        .foregroundStyle(.purple)
                    }
                }
                .frame(height: 200)
                .chartYAxisLabel("kg")
            }
            .cardStyle()
            .padding(.horizontal)

            // Weight progression chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Progression des charges")
                    .font(.headline)

                Chart {
                    ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Poids", entry.weight)
                        )
                        .foregroundStyle(.blue)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Poids", entry.weight)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxisLabel("kg")
            }
            .cardStyle()
            .padding(.horizontal)

            // Volume chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Volume total")
                    .font(.headline)

                Chart {
                    ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                        BarMark(
                            x: .value("Date", entry.date),
                            y: .value("Volume", entry.weight * Double(entry.reps))
                        )
                        .foregroundStyle(.green)
                    }
                }
                .frame(height: 200)
                .chartYAxisLabel("kg")
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }

    // MARK: - Detailed Logs

    private var detailedLogsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if detailedLogs.isEmpty {
                Text("Les détails par série apparaîtront après ta prochaine séance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                // Group logs by date
                let grouped = groupLogsByDate(detailedLogs)

                ForEach(Array(grouped.keys.sorted().reversed()), id: \.self) { dateKey in
                    if let logs = grouped[dateKey] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dateKey)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)

                            ForEach(logs.sorted(by: { $0.setNumber < $1.setNumber })) { log in
                                HStack {
                                    Text("Série \(log.setNumber)")
                                        .font(.caption)
                                        .frame(width: 60, alignment: .leading)

                                    Spacer()

                                    Text("\(log.weightKg.cleanString) kg")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)

                                    Text("x")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("\(log.reps) reps")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.orange)

                                    Spacer()

                                    Text("1RM: \(log.estimated1RM.cleanString)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Stagnation

    private var stagnationSection: some View {
        Group {
            if vm.isAnalyzingStagnation {
                HStack {
                    ProgressView()
                    Text("Analyse de progression en cours...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if let analysis = vm.stagnationAnalysis {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: analysis.isStagnating ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundStyle(stagnationColor(analysis.severity))
                        Text(analysis.isStagnating ? "Stagnation détectée" : "Bonne progression")
                            .font(.headline)
                            .foregroundStyle(stagnationColor(analysis.severity))
                    }

                    Text(analysis.analysis)
                        .font(.subheadline)

                    if !analysis.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recommandations:")
                                .font(.caption)
                                .fontWeight(.bold)
                            ForEach(analysis.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(stagnationColor(analysis.severity))
                                    Text(rec)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func loadData() {
        history = vm.exerciseHistory(name: exerciseName, modelContext: modelContext)
        detailedLogs = vm.detailedSetHistory(name: exerciseName, modelContext: modelContext)
        prs = vm.personalRecords(for: exerciseName, modelContext: modelContext)
            .sorted { $0.estimated1RM > $1.estimated1RM }

        if !history.isEmpty {
            let recentHistory = history.suffix(5).map { (weight: $0.weight, reps: $0.reps) }
            Task {
                await vm.getProgressionAdvice(for: exerciseName, history: recentHistory)
            }
        }

        // Analyze stagnation if enough data
        if detailedLogs.count >= 6 || history.count >= 3 {
            Task {
                await vm.analyzeStagnation(for: exerciseName, modelContext: modelContext)
            }
        }
    }

    private func groupLogsByDate(_ logs: [SetLog]) -> [String: [SetLog]] {
        var groups: [String: [SetLog]] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium

        for log in logs {
            let key = formatter.string(from: log.date)
            groups[key, default: []].append(log)
        }
        return groups
    }

    private func stagnationColor(_ severity: String) -> Color {
        switch severity {
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .green
        }
    }
}
