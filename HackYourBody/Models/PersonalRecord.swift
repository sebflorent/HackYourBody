import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var exerciseName: String
    var weightKg: Double
    var reps: Int
    var estimated1RM: Double
    var date: Date
    var recordType: PRType

    init(
        exerciseName: String,
        weightKg: Double,
        reps: Int,
        estimated1RM: Double,
        date: Date = .now,
        recordType: PRType = .estimated1RM
    ) {
        self.exerciseName = exerciseName
        self.weightKg = weightKg
        self.reps = reps
        self.estimated1RM = estimated1RM
        self.date = date
        self.recordType = recordType
    }
}

enum PRType: String, Codable {
    case maxWeight = "Charge max"
    case maxReps = "Reps max"
    case estimated1RM = "1RM estimé"
}
