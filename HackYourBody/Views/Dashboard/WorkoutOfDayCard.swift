import SwiftUI

struct WorkoutOfDayCard: View {
    let program: WorkoutProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.blue)
                Text("Workout du jour")
                    .font(.headline)
                Spacer()
                Text("Semaine \(program.currentWeek)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            if let nextSession = nextIncompleteSession {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextSession.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(nextSession.muscleGroupsDisplay)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label("\(nextSession.exercises.count) exercices", systemImage: "list.bullet")
                        Spacer()
                        Label(estimatedDuration(for: nextSession), systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                NavigationLink {
                    LiveWorkoutView(session: nextSession)
                } label: {
                    Text("Commencer la séance")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Toutes les séances sont complétées !")
                        .foregroundStyle(.secondary)
                }
            }

            // Program progress
            HStack {
                Text(program.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(program.completedSessions)/\(program.totalSessions) séances")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: program.progressPercentage)
                .tint(.blue)
        }
        .cardStyle()
    }

    private var nextIncompleteSession: WorkoutSession? {
        program.sessions
            .sorted { $0.dayNumber < $1.dayNumber }
            .first { !$0.isCompleted }
    }

    private func estimatedDuration(for session: WorkoutSession) -> String {
        let totalSets = session.exercises.reduce(0) { $0 + $1.sets }
        let totalRest = session.exercises.reduce(0) { $0 + $1.restSeconds * $1.sets }
        let workTime = totalSets * 45 // ~45s per set
        let totalMinutes = (totalRest + workTime) / 60
        return "~\(totalMinutes) min"
    }
}
