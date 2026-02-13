import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlan.createdAt, order: .reverse) private var mealPlans: [MealPlan]
    @Bindable var vm: RecipeViewModel
    let profile: UserProfile?

    private var todayPlan: MealPlan? { mealPlans.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = todayPlan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .padding()
        }
    }

    // MARK: - Plan Content

    private func planContent(_ plan: MealPlan) -> some View {
        VStack(spacing: 16) {
            // Macro summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Objectifs du jour")
                    .font(.headline)

                HStack(spacing: 0) {
                    macroProgress("Calories", current: plan.totalCalories, target: Double(plan.targetCalories), unit: "kcal", color: .orange)
                    macroProgress("Protéines", current: plan.totalProtein, target: Double(plan.targetProteinG), unit: "g", color: .red)
                    macroProgress("Glucides", current: plan.totalCarbs, target: Double(plan.targetCarbsG), unit: "g", color: .blue)
                    macroProgress("Lipides", current: plan.totalFat, target: Double(plan.targetFatG), unit: "g", color: .yellow)
                }
            }
            .cardStyle()

            // Meals
            ForEach(sortedMealTypes, id: \.self) { mealType in
                let mealsForType = plan.meals.filter { $0.mealType == mealType }
                if !mealsForType.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: mealType.icon)
                                .foregroundStyle(Color.accentColor)
                            Text(mealType.rawValue)
                                .font(.headline)
                        }

                        ForEach(mealsForType) { meal in
                            if let recipe = meal.recipe {
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    MealRow(meal: meal)
                                }
                            }
                        }
                    }
                }
            }

            // Generate new plan
            Button {
                Task {
                    if let profile {
                        _ = await vm.generateMealPlan(profile: profile, modelContext: modelContext)
                    }
                }
            } label: {
                Label("Regénérer le plan", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Macro Progress

    private func macroProgress(_ label: String, current: Double, target: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ProgressRing(
                progress: target > 0 ? current / target : 0,
                lineWidth: 6,
                color: color,
                size: 50
            )
            Text("\(Int(current))")
                .font(.caption)
                .fontWeight(.bold)
            Text("/ \(Int(target)) \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Pas de plan alimentaire")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Génère un plan alimentaire complet adapté à tes macros quotidiennes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    if let profile {
                        _ = await vm.generateMealPlan(profile: profile, modelContext: modelContext)
                    }
                }
            } label: {
                Label("Générer un plan", systemImage: "sparkles")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
    }

    private var sortedMealTypes: [MealType] {
        let all: [MealType] = [.breakfast, .snack, .lunch, .dinner, .postWorkout]
        return all
    }
}

struct MealRow: View {
    let meal: PlannedMeal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipe?.name ?? "Recette")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let recipe = meal.recipe {
                    HStack(spacing: 8) {
                        MacroTag(label: "\(Int(recipe.calories)) kcal", color: .orange)
                        MacroTag(label: "P:\(Int(recipe.proteinG))g", color: .red)
                    }
                }
            }

            Spacer()

            if meal.isConsumed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
