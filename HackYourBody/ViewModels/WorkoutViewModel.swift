import Foundation
import SwiftData

@MainActor @Observable
final class WorkoutViewModel {
    private let aiService = AIService.shared
    private let healthService = HealthKitService.shared

    var isGenerating = false
    var errorMessage: String?
    var progressSuggestion: String?
    var stagnationAnalysis: StagnationAnalysis?
    var isAnalyzingStagnation = false
    var lastPRMessage: String?

    // MARK: - Generate Program via AI

    func generateProgram(profile: UserProfile, modelContext: ModelContext) async {
        guard aiService.isConfigured else {
            errorMessage = "Configure ta clé API OpenAI dans les paramètres."
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            let dto = try await aiService.generateWorkoutProgram(profile: profile)

            // Deactivate existing programs
            let descriptor = FetchDescriptor<WorkoutProgram>()
            if let existingPrograms = try? modelContext.fetch(descriptor) {
                for p in existingPrograms { p.isActive = false }
            }

            // Create new program
            let program = WorkoutProgram(
                name: dto.name,
                programDescription: dto.description,
                durationWeeks: dto.durationWeeks,
                splitType: SplitType(rawValue: dto.splitType) ?? .pushPullLegs,
                startDate: .now,
                isActive: true
            )

            modelContext.insert(program)

            for sessionDTO in dto.sessions {
                let session = WorkoutSession(
                    dayNumber: sessionDTO.dayNumber,
                    name: sessionDTO.name,
                    muscleGroups: sessionDTO.muscleGroups
                )
                session.program = program
                program.sessions.append(session)

                for (index, exDTO) in sessionDTO.exercises.enumerated() {
                    let exercise = ExerciseSet(
                        exerciseName: exDTO.exerciseName,
                        muscleGroup: exDTO.muscleGroup,
                        sets: exDTO.sets,
                        targetReps: exDTO.targetReps,
                        weightKg: exDTO.weightKg,
                        restSeconds: exDTO.restSeconds,
                        notes: exDTO.notes,
                        orderIndex: index
                    )
                    exercise.session = session
                    session.exercises.append(exercise)
                }
            }

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    // MARK: - Complete Session

    func completeSession(_ session: WorkoutSession) {
        session.isCompleted = true
        session.completedAt = Date()

        // Calculate duration from first to last exercise completion
        let exerciseTimes = session.exercises.compactMap { _ in Date() }
        if let first = exerciseTimes.first {
            session.durationMinutes = Int(Date().timeIntervalSince(first) / 60)
        }
    }

    // MARK: - Log Set and Detect PR

    /// Logs a single set, persists it as a SetLog, and checks for PR
    func logSetAndCheckPR(
        exercise: ExerciseSet,
        setNumber: Int,
        weightKg: Double,
        reps: Int,
        modelContext: ModelContext
    ) -> PersonalRecord? {
        // Create and persist the SetLog
        let setLog = SetLog(
            exerciseName: exercise.exerciseName,
            setNumber: setNumber,
            weightKg: weightKg,
            reps: reps,
            date: .now,
            exerciseSet: exercise
        )
        modelContext.insert(setLog)
        exercise.setLogs.append(setLog)

        // Check for PR
        return checkForPR(
            exerciseName: exercise.exerciseName,
            weightKg: weightKg,
            reps: reps,
            modelContext: modelContext
        )
    }

    /// Check if the current set is a personal record
    private func checkForPR(
        exerciseName: String,
        weightKg: Double,
        reps: Int,
        modelContext: ModelContext
    ) -> PersonalRecord? {
        guard weightKg > 0, reps > 0 else { return nil }

        let estimated1RM = reps == 1 ? weightKg : weightKg * (1.0 + Double(reps) / 30.0)

        // Fetch existing PRs for this exercise
        let predicate = #Predicate<PersonalRecord> { pr in
            pr.exerciseName == exerciseName
        }
        let descriptor = FetchDescriptor<PersonalRecord>(predicate: predicate, sortBy: [SortDescriptor(\.estimated1RM, order: .reverse)])

        let existingPRs = (try? modelContext.fetch(descriptor)) ?? []
        let best1RM = existingPRs.first?.estimated1RM ?? 0
        let bestWeight = existingPRs.max(by: { $0.weightKg < $1.weightKg })?.weightKg ?? 0

        var newPR: PersonalRecord?

        // New estimated 1RM PR
        if estimated1RM > best1RM {
            newPR = PersonalRecord(
                exerciseName: exerciseName,
                weightKg: weightKg,
                reps: reps,
                estimated1RM: estimated1RM,
                date: .now,
                recordType: .estimated1RM
            )
            modelContext.insert(newPR!)
            lastPRMessage = "Nouveau record 1RM estimé: \(estimated1RM.cleanString) kg"
        }
        // New max weight PR (even if 1RM isn't beaten due to lower reps)
        else if weightKg > bestWeight {
            newPR = PersonalRecord(
                exerciseName: exerciseName,
                weightKg: weightKg,
                reps: reps,
                estimated1RM: estimated1RM,
                date: .now,
                recordType: .maxWeight
            )
            modelContext.insert(newPR!)
            lastPRMessage = "Nouveau record de charge: \(weightKg.cleanString) kg"
        }

        return newPR
    }

    // MARK: - Finish Session + HealthKit Write

    func finishSessionAndSaveToHealth(
        session: WorkoutSession,
        startTime: Date,
        durationMinutes: Int,
        completedSets: [String: [(weight: Double, reps: Int)]],
        modelContext: ModelContext
    ) async {
        session.isCompleted = true
        session.completedAt = Date()
        session.durationMinutes = durationMinutes

        // Update exercise data from completed sets
        for exercise in session.exercises {
            if let sets = completedSets[exercise.exerciseName], !sets.isEmpty {
                // Use the last set's weight and reps as the exercise summary
                if let lastSet = sets.last {
                    exercise.weightKg = lastSet.weight
                    exercise.actualReps = lastSet.reps
                }
            }
        }

        // Calculate total volume from actual logged sets
        let totalVolume = completedSets.values.flatMap { $0 }.reduce(0.0) { $0 + $1.weight * Double($1.reps) }

        // Write to HealthKit
        do {
            try await healthService.saveStrengthWorkout(
                startDate: startTime,
                durationMinutes: durationMinutes,
                totalVolumeKg: totalVolume,
                exerciseCount: session.exercises.count,
                sessionName: session.name
            )
        } catch {
            // Non-blocking: log but don't fail the session save
            print("HealthKit write error: \(error.localizedDescription)")
        }
    }

    // MARK: - Progressive Overload

    func getProgressionAdvice(for exerciseName: String, history: [(weight: Double, reps: Int)]) async {
        guard aiService.isConfigured else { return }

        do {
            let suggestion = try await aiService.suggestProgressiveOverload(
                exerciseName: exerciseName,
                history: history
            )
            self.progressSuggestion = suggestion
        } catch {
            // Silently fail for suggestions
        }
    }

    // MARK: - Stagnation Detection

    func analyzeStagnation(for exerciseName: String, modelContext: ModelContext) async {
        guard aiService.isConfigured else { return }

        isAnalyzingStagnation = true
        stagnationAnalysis = nil

        // Fetch recent SetLogs for this exercise
        let predicate = #Predicate<SetLog> { log in
            log.exerciseName == exerciseName
        }
        let descriptor = FetchDescriptor<SetLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let setLogs = try? modelContext.fetch(descriptor), setLogs.count >= 3 else {
            isAnalyzingStagnation = false
            return
        }

        // Group by date (session) and get best set per session
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var sessionBests: [(date: String, weight: Double, reps: Int, estimated1RM: Double)] = []
        var seenDates = Set<String>()

        for log in setLogs.reversed() {
            let dateStr = formatter.string(from: log.date)
            if !seenDates.contains(dateStr) {
                seenDates.insert(dateStr)
                sessionBests.append((
                    date: dateStr,
                    weight: log.weightKg,
                    reps: log.reps,
                    estimated1RM: log.estimated1RM
                ))
            } else {
                // Update if this set has a higher e1RM
                if let idx = sessionBests.firstIndex(where: { $0.date == dateStr }),
                   log.estimated1RM > sessionBests[idx].estimated1RM {
                    sessionBests[idx] = (
                        date: dateStr,
                        weight: log.weightKg,
                        reps: log.reps,
                        estimated1RM: log.estimated1RM
                    )
                }
            }
        }

        // Need at least 3 sessions to detect stagnation
        guard sessionBests.count >= 3 else {
            isAnalyzingStagnation = false
            return
        }

        do {
            let analysis = try await aiService.analyzeStagnation(
                exerciseName: exerciseName,
                history: Array(sessionBests.suffix(10))
            )
            self.stagnationAnalysis = analysis
        } catch {
            // Silently fail
        }

        isAnalyzingStagnation = false
    }

    // MARK: - Exercise History (from SetLogs)

    func exerciseHistory(name: String, modelContext: ModelContext) -> [(date: Date, weight: Double, reps: Int)] {
        // Try SetLogs first (new detailed data)
        let setLogPredicate = #Predicate<SetLog> { log in
            log.exerciseName == name
        }
        let setLogDescriptor = FetchDescriptor<SetLog>(
            predicate: setLogPredicate,
            sortBy: [SortDescriptor(\.date)]
        )

        if let setLogs = try? modelContext.fetch(setLogDescriptor), !setLogs.isEmpty {
            // Group by day and return best set per session
            var bestByDay: [String: (date: Date, weight: Double, reps: Int)] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for log in setLogs {
                let dayKey = formatter.string(from: log.date)
                let e1RM = log.estimated1RM
                let existing = bestByDay[dayKey]
                let existingE1RM = existing.map { $0.weight * (1.0 + Double($0.reps) / 30.0) } ?? 0

                if e1RM > existingE1RM {
                    bestByDay[dayKey] = (date: log.date, weight: log.weightKg, reps: log.reps)
                }
            }

            return bestByDay.values.sorted { $0.date < $1.date }
        }

        // Fallback: old ExerciseSet-based history
        let predicate = #Predicate<ExerciseSet> { exercise in
            exercise.exerciseName == name && exercise.actualReps != nil
        }
        let descriptor = FetchDescriptor<ExerciseSet>(predicate: predicate)

        guard let sets = try? modelContext.fetch(descriptor) else { return [] }

        return sets.compactMap { set in
            guard let session = set.session, let completedAt = session.completedAt, let reps = set.actualReps else {
                return nil
            }
            return (date: completedAt, weight: set.weightKg, reps: reps)
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Detailed Set History (per-set)

    func detailedSetHistory(name: String, modelContext: ModelContext) -> [SetLog] {
        let predicate = #Predicate<SetLog> { log in
            log.exerciseName == name
        }
        let descriptor = FetchDescriptor<SetLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Personal Records

    func personalRecords(for exerciseName: String? = nil, modelContext: ModelContext) -> [PersonalRecord] {
        if let exerciseName {
            let predicate = #Predicate<PersonalRecord> { pr in
                pr.exerciseName == exerciseName
            }
            let descriptor = FetchDescriptor<PersonalRecord>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        } else {
            let descriptor = FetchDescriptor<PersonalRecord>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        }
    }

    /// Returns the best PR for each unique exercise
    func allExerciseBestPRs(modelContext: ModelContext) -> [PersonalRecord] {
        let allPRs = personalRecords(modelContext: modelContext)
        var bestByExercise: [String: PersonalRecord] = [:]

        for pr in allPRs {
            if let existing = bestByExercise[pr.exerciseName] {
                if pr.estimated1RM > existing.estimated1RM {
                    bestByExercise[pr.exerciseName] = pr
                }
            } else {
                bestByExercise[pr.exerciseName] = pr
            }
        }

        return bestByExercise.values.sorted { $0.exerciseName < $1.exerciseName }
    }

    // MARK: - Previous Session Data

    /// Get the previous set data for an exercise (from the last completed session)
    func previousSessionData(for exerciseName: String, modelContext: ModelContext) -> [(setNumber: Int, weight: Double, reps: Int)]? {
        let predicate = #Predicate<SetLog> { log in
            log.exerciseName == exerciseName
        }
        let descriptor = FetchDescriptor<SetLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let logs = try? modelContext.fetch(descriptor), !logs.isEmpty else { return nil }

        // Find the most recent session date (not today)
        let today = Date().startOfDay
        let previousLogs = logs.filter { $0.date.startOfDay < today }

        guard !previousLogs.isEmpty else { return nil }

        let lastSessionDate = previousLogs.first!.date.startOfDay
        let lastSessionLogs = previousLogs.filter { $0.date.startOfDay == lastSessionDate }

        return lastSessionLogs
            .sorted { $0.setNumber < $1.setNumber }
            .map { (setNumber: $0.setNumber, weight: $0.weightKg, reps: $0.reps) }
    }
}
