import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding = false
    @State private var selectedTab: AppTab = .dashboard

    private var hasCompletedOnboarding: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView {
                    withAnimation(.easeInOut) {
                        showOnboarding = false
                    }
                }
            }
        }
        .task {
            // Request HealthKit authorization on first launch
            if hasCompletedOnboarding {
                try? await HealthKitService.shared.requestAuthorization()
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(AppTab.dashboard)

            ChecklistView()
                .tabItem {
                    Label("Checklist", systemImage: "checklist")
                }
                .tag(AppTab.checklist)

            WorkoutTabView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(AppTab.workouts)

            RecipeTabView()
                .tabItem {
                    Label("Recettes", systemImage: "fork.knife")
                }
                .tag(AppTab.recipes)

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(.accentColor)
    }
}

enum AppTab: String, Hashable {
    case dashboard
    case checklist
    case workouts
    case recipes
    case profile
}
