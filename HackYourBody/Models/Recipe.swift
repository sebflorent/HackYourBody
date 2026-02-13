import Foundation
import SwiftData

@Model
final class Recipe {
    var name: String
    var recipeDescription: String
    var mealType: MealType
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var ingredients: [Ingredient]
    var steps: [String]
    var tags: [String]
    var isFavorite: Bool
    var imageURL: String?
    var createdAt: Date

    init(
        name: String = "",
        recipeDescription: String = "",
        mealType: MealType = .lunch,
        prepTimeMinutes: Int = 15,
        cookTimeMinutes: Int = 20,
        servings: Int = 1,
        calories: Double = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        ingredients: [Ingredient] = [],
        steps: [String] = [],
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.name = name
        self.recipeDescription = recipeDescription
        self.mealType = mealType
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.ingredients = ingredients
        self.steps = steps
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }

    var macroSummary: String {
        "P: \(Int(proteinG))g | G: \(Int(carbsG))g | L: \(Int(fatG))g"
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Petit-déjeuner"
    case lunch = "Déjeuner"
    case dinner = "Dîner"
    case snack = "Snack"
    case postWorkout = "Post-workout"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "carrot.fill"
        case .postWorkout: return "bolt.fill"
        }
    }
}

struct Ingredient: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String

    var displayText: String {
        if unit.isEmpty {
            return "\(formattedQuantity) \(name)"
        }
        return "\(formattedQuantity) \(unit) de \(name)"
    }

    private var formattedQuantity: String {
        quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
    }
}
