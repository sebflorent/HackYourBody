import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession

    @State private var vm = WorkoutViewModel()
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
    @State private var previousData: [String: [(setNumber: Int, weight: Double, reps: Int)]] = [:]

    // PR celebration
    @State private var showPRCelebration = false
    @State private var prMessage = ""

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
            loadPreviousData()
            if let ex = currentExercise {
                prefillFromPrevious(exercise: ex)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .confirmationDialog("Terminer la séance ?", isPresented: $showFinishConfirm) {
            Button("Terminer et sauvegarder", role: .destructive) {
                Task { await finishSession() }
            }
            Button("Annuler", role: .cancel) { }
        }
        .overlay {
            if showPRCelebration {
                prCelebrationOverlay
            }
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

                // Previous session reference
                if let prev = previousData[exercise.exerciseName], !prev.isEmpty {
                    previousSessionCard(prev)
                }

                // Set indicator
                HStack(spacing: 8) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
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

    // MARK: - Previous Session Card

    private func previousSessionCard(_ sets: [(setNumber: Int, weight: Double, reps: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Séance précédente", systemImage: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                HStack {
                    Text("Série \(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(set.weight.cleanString) kg x \(set.reps)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
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

            // Session summary
            VStack(spacing: 8) {
                let totalVolume = completedSets.values.flatMap { $0 }.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                let totalSets = completedSets.values.reduce(0) { $0 + $1.count }

                HStack(spacing: 24) {
                    VStack {
                        Text("\(Int(totalVolume))")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                        Text("kg volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(totalSets)")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        Text("séries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(completedSets.keys.count)")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                        Text("exercices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                Task { await finishSession() }
            } label: {
                Label("Sauvegarder", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Text("La séance sera enregistrée dans Apple Santé")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - PR Celebration Overlay

    private var prCelebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showPRCelebration = false }
                }

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                Text("RECORD PERSONNEL !")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.yellow)

                Text(prMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation { showPRCelebration = false }
                } label: {
                    Text("Continuer")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.yellow)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(40)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func loadPreviousData() {
        for exercise in sortedExercises {
            if let prev = vm.previousSessionData(for: exercise.exerciseName, modelContext: modelContext) {
                previousData[exercise.exerciseName] = prev
            }
        }
    }

    private func prefillFromPrevious(exercise: ExerciseSet) {
        // If there's previous data, prefill with last session's first set
        if let prev = previousData[exercise.exerciseName], let first = prev.first {
            enteredWeight = first.weight
            enteredReps = first.reps
        } else {
            enteredWeight = exercise.weightKg
            enteredReps = exercise.targetReps
        }
    }

    private func logSet(for exercise: ExerciseSet) {
        var sets = completedSets[exercise.exerciseName] ?? []
        let setNumber = sets.count + 1
        sets.append((weight: enteredWeight, reps: enteredReps))
        completedSets[exercise.exerciseName] = sets

        // Persist SetLog and check for PR
        let pr = vm.logSetAndCheckPR(
            exercise: exercise,
            setNumber: setNumber,
            weightKg: enteredWeight,
            reps: enteredReps,
            modelContext: modelContext
        )

        // Show PR celebration if new PR
        if let pr = pr, let message = vm.lastPRMessage {
            prMessage = "\(exercise.exerciseName)\n\(message)"
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showPRCelebration = true
            }
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showPRCelebration = false }
            }
        }

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
            // Prefill next set: use previous session data if available
            if let prev = previousData[exercise.exerciseName],
               currentSetIndex < prev.count {
                enteredWeight = prev[currentSetIndex].weight
                enteredReps = prev[currentSetIndex].reps
            }
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
                            prefillFromPrevious(exercise: ex)
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
                    prefillFromPrevious(exercise: nextEx)
                }
            }
        }
    }

    private func finishSession() async {
        let durationMinutes = Int(elapsedTime / 60)
        await vm.finishSessionAndSaveToHealth(
            session: session,
            startTime: sessionStartTime,
            durationMinutes: durationMinutes,
            completedSets: completedSets,
            modelContext: modelContext
        )
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
