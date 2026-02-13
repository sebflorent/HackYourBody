import Foundation
import SwiftData

@MainActor @Observable
final class DashboardViewModel {
    private let healthKit = HealthKitService.shared

    var stepsToday: Int = 0
    var activeCalories: Double = 0
    var restingHeartRate: Double = 0
    var sleepHours: Double = 0
    var currentWeight: Double = 0

    var streak: Int = 0
    var todayCompliance: Double = 0

    func loadData(modelContext: ModelContext) async {
        // Fetch HealthKit data
        await healthKit.fetchTodayData()
        stepsToday = healthKit.stepsToday
        activeCalories = healthKit.activeCaloriesToday
        restingHeartRate = healthKit.restingHeartRate
        sleepHours = healthKit.sleepHoursLastNight
        currentWeight = healthKit.currentWeight

        // Compute streak
        await computeStreak(modelContext: modelContext)
    }

    func computeStreak(modelContext: ModelContext) async {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var streakCount = 0

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let predicate = #Predicate<ChecklistDay> { day in
                day.date >= currentDate && day.date < nextDay
            }

            let descriptor = FetchDescriptor<ChecklistDay>(predicate: predicate)

            do {
                let days = try modelContext.fetch(descriptor)
                if let day = days.first, day.complianceScore >= 0.7 {
                    streakCount += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    break
                }
            } catch {
                break
            }
        }

        self.streak = streakCount
    }
}
