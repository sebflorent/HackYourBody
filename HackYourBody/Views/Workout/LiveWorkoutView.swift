import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession

    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var restTimerActive = false
    @State private var restTimeRemaining = 0
    @State private var timer: Timer?
    @State private var sessionStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var enteredWeight: Double = 0
    @State private var enteredReps: Int = 0
    @State private var showFinishConfirm = false
    @State private var completedSets: [String: [(weight: Double, reps: Int)]] = [:]

    private var sortedExercises: [ExerciseSet] {
        session.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var currentExercise: ExerciseSet? {
        guard currentExerciseIndex < sortedExercises.count else { return nil }
        return sortedExercises[currentExerciseIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timer header
            timerHeader

            if restTimerActive {
                restTimerView
            } else if let exercise = currentExercise {
                exerciseView(exercise)
            } else {
                finishView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(session.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Terminer") {
                    showFinishConfirm = true
                }
                .foregroundStyle(.red)
            }
        }
        .onAppear {
            sessionStartTime = Date()
            startElapsedTimer()
            if let ex = currentExercise {
                enteredWeight = ex.weightKg
                enteredReps = ex.targetReps
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .confirmationDialog("Terminer la séance ?", isPresented: $showFinishConfirm) {
            Button("Terminer et sauvegarder", role: .destructive) {
                finishSession()
            }
            Button("Annuler", role: .cancel) { }
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Durée")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatTime(elapsedTime))
                    .font(.title3.monospacedDigit())
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Exercice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(currentExerciseIndex + 1)/\(sortedExercises.count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Exercise View

    private func exerciseView(_ exercise: ExerciseSet) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise name
                VStack(spacing: 8) {
                    Text(exercise.exerciseName)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text(exercise.muscleGroup)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Set indicator
                HStack(spacing: 8) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        let key = "\(exercise.exerciseName)-\(setIndex)"
                        let isDone = (completedSets[exercise.exerciseName]?.count ?? 0) > setIndex
                        Circle()
                            .fill(isDone ? .green : (setIndex == currentSetIndex ? .blue : .gray.opacity(0.3)))
                            .frame(width: 12, height: 12)
                    }
                }

                Text("Série \(currentSetIndex + 1) / \(exercise.sets)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Weight input
                VStack(spacing: 12) {
                    Text("Poids (kg)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 20) {
                        Button {
                            enteredWeight = max(0, enteredWeight - 2.5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                        }

                        Text("\(enteredWeight.cleanString)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(minWidth: 100)

                        Button {
                            enteredWeight += 2.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // Reps input
                VStack(spacing: 12) {
                    Text("Répétitions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 20) {
                        Button {
                            enteredReps = max(1, enteredReps - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.orange)
                        }

                        Text("\(enteredReps)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(minWidth: 80)

                        Button {
                            enteredReps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Log set button
                Button {
                    logSet(for: exercise)
                } label: {
                    Text("Valider la série")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                // Completed sets summary
                if let sets = completedSets[exercise.exerciseName], !sets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Séries validées")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                            HStack {
                                Text("Série \(index + 1)")
                                    .font(.caption)
                                Spacer()
                                Text("\(set.weight.cleanString) kg x \(set.reps) reps")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Rest Timer

    private var restTimerView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Repos")
                .font(.title)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: CGFloat(restTimeRemaining) / CGFloat(currentExercise?.restSeconds ?? 90))
                    .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: restTimeRemaining)

                Text("\(restTimeRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }

            Button {
                skipRest()
            } label: {
                Text("Passer le repos")
                    .font(.headline)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
    }

    // MARK: - Finish View

    private var finishView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)

            Text("Séance terminée !")
                .font(.title)
                .fontWeight(.bold)

            Text(formatTime(elapsedTime))
                .font(.title2)
                .foregroundStyle(.secondary)

            Button {
                finishSession()
            } label: {
                Text("Sauvegarder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Actions

    private func logSet(for exercise: ExerciseSet) {
        var sets = completedSets[exercise.exerciseName] ?? []
        sets.append((weight: enteredWeight, reps: enteredReps))
        completedSets[exercise.exerciseName] = sets

        if sets.count >= exercise.sets {
            // All sets done, save and move to next exercise
            exercise.weightKg = enteredWeight
            exercise.actualReps = enteredReps

            if currentExerciseIndex + 1 < sortedExercises.count {
                // Start rest before next exercise
                startRestTimer(seconds: exercise.restSeconds)
            } else {
                // Move to finish
                currentExerciseIndex += 1
            }
            currentSetIndex = 0
        } else {
            currentSetIndex = sets.count
            startRestTimer(seconds: exercise.restSeconds)
        }
    }

    private func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        restTimerActive = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                t.invalidate()
                restTimerActive = false
                if currentExerciseIndex < sortedExercises.count {
                    let nextEx = sortedExercises[currentExerciseIndex]
                    // Only advance to next exercise if all sets are done
                    if (completedSets[nextEx.exerciseName]?.count ?? 0) >= nextEx.sets {
                        currentExerciseIndex += 1
                        if let ex = currentExercise {
                            enteredWeight = ex.weightKg
                            enteredReps = ex.targetReps
                        }
                    }
                }
            }
        }
    }

    private func skipRest() {
        timer?.invalidate()
        restTimerActive = false
        if currentExerciseIndex < sortedExercises.count {
            let ex = sortedExercises[currentExerciseIndex]
            if (completedSets[ex.exerciseName]?.count ?? 0) >= ex.sets {
                currentExerciseIndex += 1
                if let nextEx = currentExercise {
                    enteredWeight = nextEx.weightKg
                    enteredReps = nextEx.targetReps
                }
            }
        }
    }

    private func finishSession() {
        session.isCompleted = true
        session.completedAt = Date()
        session.durationMinutes = Int(elapsedTime / 60)
        timer?.invalidate()
        dismiss()
    }

    private func startElapsedTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(sessionStartTime)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
