import Foundation
import SwiftData

@MainActor @Observable
final class RecipeViewModel {
    private let aiService = AIService.shared

    var isGenerating = false
    var errorMessage: String?
    var selectedMealType: MealType = .lunch
    var searchText: String = ""
    var filterFavoritesOnly: Bool = false

    // MARK: - Generate Recipes

    func generateRecipes(profile: UserProfile, mealType: MealType, count: Int = 3, modelContext: ModelContext) async {
        guard aiService.isConfigured else {
            errorMessage = "Configure ta clé API OpenAI dans les paramètres."
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            let dtos = try await aiService.generateRecipes(profile: profile, mealType: mealType, count: count)

            for dto in dtos {
                let recipe = Recipe(
                    name: dto.name,
                    recipeDescription: dto.description,
                    mealType: mealTypeFromString(dto.mealType) ?? mealType,
                    prepTimeMinutes: dto.prepTimeMinutes,
                    cookTimeMinutes: dto.cookTimeMinutes,
                    servings: dto.servings,
                    calories: dto.calories,
                    proteinG: dto.proteinG,
                    carbsG: dto.carbsG,
                    fatG: dto.fatG,
                    ingredients: dto.ingredients.map {
                        Ingredient(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                    },
                    steps: dto.steps,
                    tags: dto.tags
                )
                modelContext.insert(recipe)
            }
            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    // MARK: - Generate Meal Plan

    func generateMealPlan(profile: UserProfile, modelContext: ModelContext) async -> MealPlan? {
        guard aiService.isConfigured else {
            errorMessage = "Configure ta clé API OpenAI dans les paramètres."
            return nil
        }

        isGenerating = true
        errorMessage = nil

        do {
            let dto = try await aiService.generateMealPlan(profile: profile)

            let plan = MealPlan(
                date: .now,
                targetCalories: profile.dailyCalorieTarget,
                targetProteinG: profile.dailyProteinTargetG,
                targetCarbsG: profile.dailyCarbsTargetG,
                targetFatG: profile.dailyFatTargetG
            )

            modelContext.insert(plan)

            for mealDTO in dto.meals {
                let recipe = Recipe(
                    name: mealDTO.recipe.name,
                    recipeDescription: mealDTO.recipe.description,
                    mealType: mealTypeFromString(mealDTO.recipe.mealType) ?? .lunch,
                    prepTimeMinutes: mealDTO.recipe.prepTimeMinutes,
                    cookTimeMinutes: mealDTO.recipe.cookTimeMinutes,
                    servings: mealDTO.recipe.servings,
                    calories: mealDTO.recipe.calories,
                    proteinG: mealDTO.recipe.proteinG,
                    carbsG: mealDTO.recipe.carbsG,
                    fatG: mealDTO.recipe.fatG,
                    ingredients: mealDTO.recipe.ingredients.map {
                        Ingredient(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                    },
                    steps: mealDTO.recipe.steps,
                    tags: mealDTO.recipe.tags
                )
                modelContext.insert(recipe)

                let meal = PlannedMeal(
                    mealType: mealTypeFromString(mealDTO.mealType) ?? .lunch,
                    recipe: recipe
                )
                meal.plan = plan
                plan.meals.append(meal)
            }

            isGenerating = false
            return plan
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
            return nil
        }
    }

    // MARK: - Shopping List

    func generateShoppingList(from recipes: [Recipe]) -> [ShoppingItem] {
        var itemMap: [String: ShoppingItem] = [:]

        for recipe in recipes {
            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased()
                if var existing = itemMap[key] {
                    existing.quantity += ingredient.quantity
                    itemMap[key] = existing
                } else {
                    itemMap[key] = ShoppingItem(
                        name: ingredient.name,
                        quantity: ingredient.quantity,
                        unit: ingredient.unit
                    )
                }
            }
        }

        return itemMap.values.sorted { $0.name < $1.name }
    }

    // MARK: - Filter Recipes

    func filteredRecipes(_ recipes: [Recipe]) -> [Recipe] {
        var filtered = recipes

        if filterFavoritesOnly {
            filtered = filtered.filter(\.isFavorite)
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return filtered
    }

    // MARK: - Helper

    private func mealTypeFromString(_ string: String) -> MealType? {
        MealType.allCases.first { $0.rawValue == string }
    }
}

struct ShoppingItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var isChecked: Bool = false

    var displayText: String {
        let qty = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        if unit.isEmpty {
            return "\(qty) \(name)"
        }
        return "\(qty) \(unit) \(name)"
    }
}
