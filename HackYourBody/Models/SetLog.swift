import Foundation
import SwiftData

@Model
final class SetLog {
    var exerciseName: String
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var date: Date
    var exerciseSet: ExerciseSet?

    init(
        exerciseName: String,
        setNumber: Int,
        weightKg: Double,
        reps: Int,
        date: Date = .now,
        exerciseSet: ExerciseSet? = nil
    ) {
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.date = date
        self.exerciseSet = exerciseSet
    }

    var volume: Double {
        weightKg * Double(reps)
    }

    /// Estimated 1RM using Epley formula: weight * (1 + reps / 30)
    var estimated1RM: Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }
}
