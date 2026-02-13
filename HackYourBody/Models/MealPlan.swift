import Foundation
import SwiftData

@Model
final class MealPlan {
    var date: Date
    var targetCalories: Int
    var targetProteinG: Int
    var targetCarbsG: Int
    var targetFatG: Int
    @Relationship(deleteRule: .cascade) var meals: [PlannedMeal]
    var createdAt: Date

    init(
        date: Date = .now,
        targetCalories: Int = 2200,
        targetProteinG: Int = 160,
        targetCarbsG: Int = 220,
        targetFatG: Int = 70
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.targetCalories = targetCalories
        self.targetProteinG = targetProteinG
        self.targetCarbsG = targetCarbsG
        self.targetFatG = targetFatG
        self.meals = []
        self.createdAt = Date()
    }

    var totalCalories: Double {
        meals.reduce(0) { $0 + ($1.recipe?.calories ?? 0) }
    }

    var totalProtein: Double {
        meals.reduce(0) { $0 + ($1.recipe?.proteinG ?? 0) }
    }

    var totalCarbs: Double {
        meals.reduce(0) { $0 + ($1.recipe?.carbsG ?? 0) }
    }

    var totalFat: Double {
        meals.reduce(0) { $0 + ($1.recipe?.fatG ?? 0) }
    }
}

@Model
final class PlannedMeal {
    var mealType: MealType
    var recipe: Recipe?
    var isConsumed: Bool
    var plan: MealPlan?

    init(mealType: MealType = .lunch, recipe: Recipe? = nil, isConsumed: Bool = false) {
        self.mealType = mealType
        self.recipe = recipe
        self.isConsumed = isConsumed
    }
}
