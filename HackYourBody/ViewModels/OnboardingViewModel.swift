import Foundation
import SwiftData
import SwiftUI

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var name: String = ""
    var weightKg: Double = 80
    var heightCm: Double = 178
    var age: Int = 30
    var goal: FitnessGoal = .recomposition
    var activityLevel: ActivityLevel = .moderate
    var trainingDaysPerWeek: Int = 4
    var selectedEquipment: Set<String> = []
    var selectedDietaryPrefs: Set<String> = []

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case profile = 1
        case goal = 2
        case activity = 3
        case equipment = 4
        case dietary = 5
        case summary = 6

        var title: String {
            switch self {
            case .welcome: return "Bienvenue"
            case .profile: return "Ton profil"
            case .goal: return "Ton objectif"
            case .activity: return "Ton activité"
            case .equipment: return "Ton équipement"
            case .dietary: return "Alimentation"
            case .summary: return "Résumé"
            }
        }

        var progress: Double {
            Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome: return true
        case .profile: return !name.isEmpty && weightKg > 0 && heightCm > 0 && age > 0
        case .goal: return true
        case .activity: return true
        case .equipment: return !selectedEquipment.isEmpty
        case .dietary: return true
        case .summary: return true
        }
    }

    func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    func previousStep() {
        guard let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    func computeMacros() -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        // Mifflin-St Jeor
        let bmr = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age) + 5.0
        let tdee = Int(bmr * activityLevel.multiplier)

        let calories: Int
        switch goal {
        case .muscleGain: calories = tdee + 300
        case .fatLoss: calories = tdee - 500
        case .recomposition: calories = tdee - 200
        case .maintenance: calories = tdee
        }

        let protein = Int(weightKg * 2.0)  // 2g/kg for recomp
        let fat = Int(Double(calories) * 0.25 / 9.0)
        let remainingCalories = calories - (protein * 4) - (fat * 9)
        let carbs = max(remainingCalories / 4, 50)

        return (calories, protein, carbs, fat)
    }

    func createProfile(in modelContext: ModelContext) {
        let macros = computeMacros()
        let profile = UserProfile(
            name: name,
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            goal: goal,
            activityLevel: activityLevel,
            dietaryPreferences: Array(selectedDietaryPrefs),
            trainingDaysPerWeek: trainingDaysPerWeek,
            equipmentAvailable: Array(selectedEquipment),
            dailyCalorieTarget: macros.calories,
            dailyProteinTargetG: macros.protein,
            dailyCarbsTargetG: macros.carbs,
            dailyFatTargetG: macros.fat,
            onboardingCompleted: true
        )
        modelContext.insert(profile)
    }
}
