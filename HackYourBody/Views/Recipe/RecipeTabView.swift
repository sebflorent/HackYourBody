import SwiftUI
import SwiftData

struct RecipeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    @State private var vm = RecipeViewModel()
    @State private var selectedTab: RecipeSubTab = .recipes

    private var profile: UserProfile? { profiles.first }

    enum RecipeSubTab: String, CaseIterable {
        case recipes = "Recettes"
        case mealPlan = "Plan"
        case shopping = "Courses"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sub-tab picker
                Picker("", selection: $selectedTab) {
                    ForEach(RecipeSubTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .recipes:
                    RecipeListView(recipes: allRecipes, vm: vm, profile: profile)
                case .mealPlan:
                    MealPlanView(vm: vm, profile: profile)
                case .shopping:
                    ShoppingListView(vm: vm, recipes: allRecipes)
                }
            }
            .navigationTitle("Recettes")
            .overlay {
                if vm.isGenerating {
                    generatingOverlay
                }
            }
            .alert("Erreur", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("L'IA génère tes recettes...")
                    .font(.headline)
                Text("Cela peut prendre quelques secondes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
