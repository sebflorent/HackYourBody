import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var exerciseName: String
    var muscleGroup: String
    var sets: Int
    var targetReps: Int
    var actualReps: Int?
    var weightKg: Double
    var restSeconds: Int
    var notes: String?
    var orderIndex: Int
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade) var setLogs: [SetLog] = []

    init(
        exerciseName: String,
        muscleGroup: String = "",
        sets: Int = 3,
        targetReps: Int = 10,
        actualReps: Int? = nil,
        weightKg: Double = 0,
        restSeconds: Int = 90,
        notes: String? = nil,
        orderIndex: Int = 0
    ) {
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.sets = sets
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weightKg = weightKg
        self.restSeconds = restSeconds
        self.notes = notes
        self.orderIndex = orderIndex
    }

    var totalVolume: Double {
        weightKg * Double(actualReps ?? targetReps) * Double(sets)
    }

    var isCompleted: Bool {
        actualReps != nil
    }
}
