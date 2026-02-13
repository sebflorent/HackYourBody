import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exerciseName: String

    @State private var vm = WorkoutViewModel()
    @State private var history: [(date: Date, weight: Double, reps: Int)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if history.isEmpty {
                    ContentUnavailableView(
                        "Pas encore d'historique",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Les données apparaîtront après ta première séance")
                    )
                } else {
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

                    // History list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Détail par séance")
                            .font(.headline)

                        ForEach(Array(history.reversed().enumerated()), id: \.offset) { _, entry in
                            HStack {
                                Text(entry.date.shortFormatted)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(entry.weight.cleanString) kg x \(entry.reps) reps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .cardStyle()

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
                    }
                }
            }
            .padding()
        }
        .navigationTitle(exerciseName)
        .onAppear {
            history = vm.exerciseHistory(name: exerciseName, modelContext: modelContext)
            if !history.isEmpty {
                let recentHistory = history.suffix(5).map { (weight: $0.weight, reps: $0.reps) }
                Task {
                    await vm.getProgressionAdvice(for: exerciseName, history: recentHistory)
                }
            }
        }
    }
}
