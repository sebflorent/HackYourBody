import SwiftUI
import SwiftData

struct RecipeListView: View {
    let recipes: [Recipe]
    @Bindable var vm: RecipeViewModel
    let profile: UserProfile?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Rechercher...", text: $vm.searchText)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    vm.filterFavoritesOnly.toggle()
                } label: {
                    Image(systemName: vm.filterFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(vm.filterFavoritesOnly ? .red : .secondary)
                }
            }
            .padding(.horizontal)

            // Meal type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MealType.allCases) { type in
                        Button {
                            vm.selectedMealType = type
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(vm.selectedMealType == type ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(vm.selectedMealType == type ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            let filtered = vm.filteredRecipes(recipes).filter { $0.mealType == vm.selectedMealType }

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeCard(recipe: recipe)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Pas de recettes")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Génère des recettes adaptées à tes macros avec l'IA")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    if let profile {
                        await vm.generateRecipes(
                            profile: profile,
                            mealType: vm.selectedMealType,
                            modelContext: modelContext
                        )
                    }
                }
            } label: {
                Label("Générer des recettes", systemImage: "sparkles")
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
}

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: recipe.mealType.icon)
                            .foregroundStyle(Color.accentColor)
                        Text(recipe.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Text(recipe.recipeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 12) {
                MacroTag(label: "\(Int(recipe.calories)) kcal", color: .orange)
                MacroTag(label: "P: \(Int(recipe.proteinG))g", color: .red)
                MacroTag(label: "G: \(Int(recipe.carbsG))g", color: .blue)
                MacroTag(label: "L: \(Int(recipe.fatG))g", color: .yellow)
            }

            HStack {
                Label("\(recipe.prepTimeMinutes) min prep", systemImage: "clock")
                Spacer()
                Label("\(recipe.servings) portion\(recipe.servings > 1 ? "s" : "")", systemImage: "person")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MacroTag: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
