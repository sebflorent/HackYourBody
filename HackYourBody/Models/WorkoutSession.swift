import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var dayNumber: Int
    var name: String
    var muscleGroups: [String]
    var isCompleted: Bool
    var completedAt: Date?
    var durationMinutes: Int?
    var notes: String?
    var program: WorkoutProgram?
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseSet]
    var createdAt: Date

    init(
        dayNumber: Int = 1,
        name: String = "",
        muscleGroups: [String] = [],
        isCompleted: Bool = false
    ) {
        self.dayNumber = dayNumber
        self.name = name
        self.muscleGroups = muscleGroups
        self.isCompleted = isCompleted
        self.exercises = []
        self.createdAt = Date()
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.weightKg * Double(exercise.actualReps ?? exercise.targetReps) * Double(exercise.sets)
        }
    }

    var muscleGroupsDisplay: String {
        muscleGroups.joined(separator: " / ")
    }
}
