import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var goal: FitnessGoal
    var activityLevel: ActivityLevel
    var dietaryPreferences: [String]
    var trainingDaysPerWeek: Int
    var equipmentAvailable: [String]
    var dailyCalorieTarget: Int
    var dailyProteinTargetG: Int
    var dailyCarbsTargetG: Int
    var dailyFatTargetG: Int
    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String = "",
        weightKg: Double = 80,
        heightCm: Double = 178,
        age: Int = 30,
        goal: FitnessGoal = .recomposition,
        activityLevel: ActivityLevel = .moderate,
        dietaryPreferences: [String] = [],
        trainingDaysPerWeek: Int = 4,
        equipmentAvailable: [String] = [],
        dailyCalorieTarget: Int = 2200,
        dailyProteinTargetG: Int = 160,
        dailyCarbsTargetG: Int = 220,
        dailyFatTargetG: Int = 70,
        onboardingCompleted: Bool = false
    ) {
        self.name = name
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.goal = goal
        self.activityLevel = activityLevel
        self.dietaryPreferences = dietaryPreferences
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.equipmentAvailable = equipmentAvailable
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTargetG = dailyProteinTargetG
        self.dailyCarbsTargetG = dailyCarbsTargetG
        self.dailyFatTargetG = dailyFatTargetG
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var bmi: Double {
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    var tdeeEstimate: Int {
        // Mifflin-St Jeor formula
        let bmr = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age) + 5.0
        return Int(bmr * activityLevel.multiplier)
    }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case muscleGain = "Prise de muscle"
    case fatLoss = "Perte de gras"
    case recomposition = "Recomposition"
    case maintenance = "Maintien"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .fatLoss: return "flame.fill"
        case .recomposition: return "arrow.triangle.2.circlepath"
        case .maintenance: return "equal.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .muscleGain: return "Prendre du muscle avec un surplus calorique modéré"
        case .fatLoss: return "Perdre du gras avec un déficit calorique contrôlé"
        case .recomposition: return "Prendre du muscle et perdre du gras simultanément"
        case .maintenance: return "Maintenir votre physique actuel"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sédentaire"
    case light = "Légèrement actif"
    case moderate = "Modérément actif"
    case active = "Très actif"
    case veryActive = "Extrêmement actif"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}
