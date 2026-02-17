import SwiftUI
import SwiftData

@main
struct HackYourBodyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            UserProfile.self,
            ChecklistDay.self,
            ChecklistItem.self,
            WorkoutProgram.self,
            WorkoutSession.self,
            ExerciseSet.self,
            SetLog.self,
            PersonalRecord.self,
            Recipe.self,
            MealPlan.self,
            PlannedMeal.self,
            ChatMessage.self,
            ProgressPhoto.self,
            BodyMeasurement.self
        ])
    }
}
