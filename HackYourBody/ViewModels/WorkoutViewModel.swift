import Foundation
import SwiftData

@MainActor @Observable
final class WorkoutViewModel {
    private let aiService = AIService.shared

    var isGenerating = false
    var errorMessage: String?
    var progressSuggestion: String?

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

    // MARK: - Exercise History

    func exerciseHistory(name: String, modelContext: ModelContext) -> [(date: Date, weight: Double, reps: Int)] {
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
}
