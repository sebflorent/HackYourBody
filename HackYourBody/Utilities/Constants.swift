import SwiftUI

enum AppConstants {
    static let appName = "Hack Your Body"
    static let defaultStepGoal = 10_000
    static let defaultSleepGoalHours = 7.0
    static let defaultWaterGoalLiters = 3.0
    static let defaultCreatineG = 5.0

    enum Equipment: String, CaseIterable, Identifiable {
        case barbell = "Barre"
        case dumbbells = "Haltères"
        case cableMachine = "Poulie / Câbles"
        case pullUpBar = "Barre de traction"
        case bench = "Banc"
        case squat = "Rack à squat"
        case machines = "Machines guidées"
        case resistanceBands = "Élastiques"
        case kettlebell = "Kettlebell"
        case bodyweight = "Poids du corps"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .barbell: return "figure.strengthtraining.traditional"
            case .dumbbells: return "dumbbell.fill"
            case .cableMachine: return "cable.connector"
            case .pullUpBar: return "figure.climbing"
            case .bench: return "rectangle.fill"
            case .squat: return "square.stack.3d.up.fill"
            case .machines: return "gearshape.2.fill"
            case .resistanceBands: return "lasso"
            case .kettlebell: return "figure.highintensity.intervaltraining"
            case .bodyweight: return "figure.stand"
            }
        }
    }

    enum DietaryPreference: String, CaseIterable, Identifiable {
        case none = "Aucune restriction"
        case vegetarian = "Végétarien"
        case vegan = "Végan"
        case glutenFree = "Sans gluten"
        case lactoseFree = "Sans lactose"
        case halal = "Halal"
        case lowCarb = "Low carb"
        case highProtein = "High protein"

        var id: String { rawValue }
    }
}

enum AppColors {
    static let accent = Color("AccentColor")
    static let training = Color.blue
    static let nutrition = Color.green
    static let health = Color.red
    static let supplement = Color.purple
    static let custom = Color.orange

    static func forCategory(_ category: ChecklistCategory) -> Color {
        switch category {
        case .training: return training
        case .nutrition: return nutrition
        case .supplement: return supplement
        case .health: return health
        case .custom: return custom
        }
    }
}
