import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \ChecklistDay.date) private var checklistDays: [ChecklistDay]
    @Query(sort: \WorkoutSession.createdAt) private var sessions: [WorkoutSession]

    @State private var stepsHistory: [(date: Date, steps: Int)] = []
    @State private var selectedTimeRange: TimeRange = .month

    private var profile: UserProfile? { profiles.first }
    private let healthKit = HealthKitService.shared

    enum TimeRange: String, CaseIterable {
        case week = "7J"
        case month = "30J"
        case quarter = "90J"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range picker
                Picker("Période", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Compliance chart
                complianceSection

                // Workout volume chart
                workoutVolumeSection

                // Steps chart
                stepsSection

                // Summary stats
                summarySection
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistiques")
        .task {
            stepsHistory = await healthKit.fetchStepsHistory(days: selectedTimeRange.days)
        }
        .onChange(of: selectedTimeRange) { _, _ in
            Task {
                stepsHistory = await healthKit.fetchStepsHistory(days: selectedTimeRange.days)
            }
        }
    }

    // MARK: - Compliance Chart

    private var complianceSection: some View {
        let filteredDays = checklistDays.filter {
            $0.date >= Date().daysAgo(selectedTimeRange.days)
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Compliance checklist")
                .font(.headline)

            if filteredDays.isEmpty {
                Text("Pas encore de données")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(filteredDays, id: \.date) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Compliance", day.complianceScore * 100)
                        )
                        .foregroundStyle(
                            day.complianceScore >= 0.8 ? .green :
                            day.complianceScore >= 0.5 ? .orange : .red
                        )
                    }

                    RuleMark(y: .value("Objectif", 80))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 3]))
                }
                .frame(height: 180)
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("%")
            }

            // Average compliance
            let avgCompliance = filteredDays.isEmpty ? 0 :
                filteredDays.reduce(0.0) { $0 + $1.complianceScore } / Double(filteredDays.count) * 100
            HStack {
                Text("Moyenne")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(avgCompliance))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(avgCompliance >= 80 ? .green : .orange)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Workout Volume

    private var workoutVolumeSection: some View {
        let completedSessions = sessions.filter {
            $0.isCompleted && ($0.completedAt ?? .distantPast) >= Date().daysAgo(selectedTimeRange.days)
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Volume d'entraînement")
                .font(.headline)

            if completedSessions.isEmpty {
                Text("Pas encore de séances complétées")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(completedSessions) { session in
                        if let date = session.completedAt {
                            BarMark(
                                x: .value("Date", date, unit: .day),
                                y: .value("Volume", session.totalVolume / 1000)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                }
                .frame(height: 180)
                .chartYAxisLabel("tonnes")
            }

            // Total volume
            let totalVolume = completedSessions.reduce(0.0) { $0 + $1.totalVolume }
            HStack {
                Text("Volume total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(totalVolume / 1000)) tonnes")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pas quotidiens")
                .font(.headline)

            if stepsHistory.isEmpty {
                Text("Connecte Apple Health pour voir tes pas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(stepsHistory, id: \.date) { entry in
                        BarMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Pas", entry.steps)
                        )
                        .foregroundStyle(entry.steps >= AppConstants.defaultStepGoal ? .green : .gray)
                    }

                    RuleMark(y: .value("Objectif", AppConstants.defaultStepGoal))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 3]))
                }
                .frame(height: 180)
            }

            let avgSteps = stepsHistory.isEmpty ? 0 :
                stepsHistory.reduce(0) { $0 + $1.steps } / stepsHistory.count
            HStack {
                Text("Moyenne")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(avgSteps) pas/jour")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Summary

    private var summarySection: some View {
        let completedSessions = sessions.filter { $0.isCompleted }
        let daysWithChecklist = checklistDays.count
        let perfectDays = checklistDays.filter { $0.complianceScore >= 1.0 }.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("Résumé global")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryStatCard(icon: "figure.run", label: "Séances", value: "\(completedSessions.count)", color: .blue)
                SummaryStatCard(icon: "calendar", label: "Jours actifs", value: "\(daysWithChecklist)", color: .green)
                SummaryStatCard(icon: "star.fill", label: "Jours parfaits", value: "\(perfectDays)", color: .yellow)
                SummaryStatCard(icon: "scalemass.fill", label: "Poids actuel", value: healthKit.currentWeight > 0 ? "\(healthKit.currentWeight.cleanString) kg" : "--", color: .purple)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
}

struct SummaryStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
