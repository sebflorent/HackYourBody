import SwiftUI

struct SessionDetailView: View {
    let session: WorkoutSession
    let vm: WorkoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        if session.isCompleted {
                            Label("Complétée", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text(session.muscleGroupsDisplay)
                        .foregroundStyle(.secondary)

                    if let completedAt = session.completedAt {
                        Label(completedAt.shortFormatted, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Exercises
                ForEach(session.exercises.sorted { $0.orderIndex < $1.orderIndex }) { exercise in
                    ExerciseCard(exercise: exercise)
                }

                // Start workout button
                if !session.isCompleted {
                    NavigationLink {
                        LiveWorkoutView(session: session)
                    } label: {
                        Label("Commencer la séance", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }

                // Volume summary
                if session.isCompleted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Résumé")
                            .font(.headline)

                        HStack(spacing: 20) {
                            VStack {
                                Text("\(Int(session.totalVolume))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                Text("kg volume")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let duration = session.durationMinutes {
                                VStack {
                                    Text("\(duration)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                    Text("minutes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack {
                                Text("\(session.exercises.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                                Text("exercices")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .cardStyle()
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseCard: View {
    let exercise: ExerciseSet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                    Text(exercise.muscleGroup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if exercise.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 16) {
                ExerciseMetric(label: "Séries", value: "\(exercise.sets)")
                ExerciseMetric(label: "Reps", value: "\(exercise.targetReps)")
                ExerciseMetric(label: "Poids", value: exercise.weightKg > 0 ? "\(exercise.weightKg.cleanString) kg" : "--")
                ExerciseMetric(label: "Repos", value: "\(exercise.restSeconds)s")
            }

            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct ExerciseMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
