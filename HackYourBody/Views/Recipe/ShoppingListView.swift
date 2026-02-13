import SwiftUI
import SwiftData

struct ShoppingListView: View {
    let vm: RecipeViewModel
    let recipes: [Recipe]

    @State private var shoppingItems: [ShoppingItem] = []
    @State private var selectedRecipes: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            if shoppingItems.isEmpty && selectedRecipes.isEmpty {
                emptyState
            } else if selectedRecipes.isEmpty {
                recipeSelector
            } else {
                shoppingList
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "cart")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Liste de courses")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Sélectionne les recettes que tu veux préparer pour générer ta liste de courses")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !recipes.isEmpty {
                Button("Sélectionner des recettes") {
                    // Show recipe selector - just toggle the state
                    selectedRecipes = Set(recipes.prefix(3).map(\.name))
                    generateList()
                }
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

    // MARK: - Recipe Selector

    private var recipeSelector: some View {
        VStack(spacing: 16) {
            Text("Sélectionne les recettes")
                .font(.headline)
                .padding(.top)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(recipes) { recipe in
                        let isSelected = selectedRecipes.contains(recipe.name)
                        Button {
                            if isSelected {
                                selectedRecipes.remove(recipe.name)
                            } else {
                                selectedRecipes.insert(recipe.name)
                            }
                        } label: {
                            HStack {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                                Text(recipe.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(recipe.macroSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal)
            }

            if !selectedRecipes.isEmpty {
                Button {
                    generateList()
                } label: {
                    Text("Générer la liste (\(selectedRecipes.count) recettes)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
        }
    }

    // MARK: - Shopping List

    private var shoppingList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(shoppingItems.count) ingrédients")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Modifier") {
                    shoppingItems = []
                    selectedRecipes = []
                }
                .font(.caption)
            }
            .padding()

            List {
                ForEach(Array($shoppingItems.enumerated()), id: \.element.id) { index, $item in
                    HStack {
                        Button {
                            shoppingItems[index].isChecked.toggle()
                        } label: {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isChecked ? .green : .secondary)
                        }

                        Text(item.displayText)
                            .strikethrough(item.isChecked)
                            .foregroundStyle(item.isChecked ? .secondary : .primary)

                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Generate

    private func generateList() {
        let selectedRecipeObjects = recipes.filter { selectedRecipes.contains($0.name) }
        shoppingItems = vm.generateShoppingList(from: selectedRecipeObjects)
    }
}
