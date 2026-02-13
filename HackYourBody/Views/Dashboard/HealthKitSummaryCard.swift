import SwiftUI

struct HealthKitSummaryCard: View {
    let steps: Int
    let activeCalories: Double
    let heartRate: Double
    let sleepHours: Double
    let weight: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Apple Health")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                HealthMetricTile(
                    icon: "figure.walk",
                    title: "Pas",
                    value: "\(steps)",
                    subtitle: "/ \(AppConstants.defaultStepGoal)",
                    color: .green,
                    progress: Double(steps) / Double(AppConstants.defaultStepGoal)
                )

                HealthMetricTile(
                    icon: "flame.fill",
                    title: "Calories actives",
                    value: "\(Int(activeCalories))",
                    subtitle: "kcal",
                    color: .orange,
                    progress: nil
                )

                HealthMetricTile(
                    icon: "heart.fill",
                    title: "FC repos",
                    value: heartRate > 0 ? "\(Int(heartRate))" : "--",
                    subtitle: "bpm",
                    color: .red,
                    progress: nil
                )

                HealthMetricTile(
                    icon: "moon.zzz.fill",
                    title: "Sommeil",
                    value: sleepHours > 0 ? String(format: "%.1f", sleepHours) : "--",
                    subtitle: "/ \(Int(AppConstants.defaultSleepGoalHours))h",
                    color: .indigo,
                    progress: sleepHours > 0 ? sleepHours / AppConstants.defaultSleepGoalHours : nil
                )
            }

            if weight > 0 {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(.blue)
                    Text("Poids actuel")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(weight.cleanString) kg")
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
        .cardStyle()
    }
}

struct HealthMetricTile: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let progress {
                ProgressView(value: min(progress, 1.0))
                    .tint(color)
            }
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
