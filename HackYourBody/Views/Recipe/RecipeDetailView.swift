import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: recipe.mealType.icon)
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Text(recipe.mealType.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            recipe.isFavorite.toggle()
                        } label: {
                            Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(recipe.isFavorite ? .red : .secondary)
                        }
                    }

                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(recipe.recipeDescription)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Label("\(recipe.prepTimeMinutes) min prep", systemImage: "clock")
                        Label("\(recipe.cookTimeMinutes) min cuisson", systemImage: "flame")
                        Label("\(recipe.servings) pers.", systemImage: "person")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Macros
                MacroDonutChart(
                    protein: recipe.proteinG,
                    carbs: recipe.carbsG,
                    fat: recipe.fatG,
                    calories: recipe.calories
                )
                .padding(.horizontal)

                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingrédients")
                        .font(.title3)
                        .fontWeight(.bold)

                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                            Text(ingredient.displayText)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Préparation")
                        .font(.title3)
                        .fontWeight(.bold)

                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor)
                                .clipShape(Circle())

                            Text(step)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)

                // Tags
                if !recipe.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 6) {
                            ForEach(recipe.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
