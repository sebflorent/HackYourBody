import Foundation
import SwiftData

@MainActor @Observable
final class ChecklistViewModel {
    var selectedDate: Date = .now

    func getOrCreateToday(modelContext: ModelContext) -> ChecklistDay {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<ChecklistDay> { day in
            day.date >= startOfDay && day.date < endOfDay
        }
        let descriptor = FetchDescriptor<ChecklistDay>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newDay = ChecklistDay(date: selectedDate)
        let defaultItems = ChecklistDay.defaultItems()
        for item in defaultItems {
            item.day = newDay
            newDay.items.append(item)
        }
        modelContext.insert(newDay)
        return newDay
    }

    func addCustomItem(label: String, to day: ChecklistDay, modelContext: ModelContext) {
        let item = ChecklistItem(label: label, icon: "star.fill", category: .custom)
        item.day = day
        day.items.append(item)
    }

    func removeItem(_ item: ChecklistItem, from day: ChecklistDay, modelContext: ModelContext) {
        day.items.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }

    func updateHealthKitItems(day: ChecklistDay) async {
        let healthKit = HealthKitService.shared
        await healthKit.fetchTodayData()

        // Auto-fill steps
        if let stepsItem = day.items.first(where: { $0.label.contains("pas") && $0.isAutoFilled }) {
            stepsItem.isCompleted = healthKit.stepsToday >= AppConstants.defaultStepGoal
            if stepsItem.isCompleted { stepsItem.completedAt = Date() }
        }

        // Auto-fill sleep
        if let sleepItem = day.items.first(where: { $0.label.contains("Sommeil") && $0.isAutoFilled }) {
            sleepItem.isCompleted = healthKit.sleepHoursLastNight >= AppConstants.defaultSleepGoalHours
            if sleepItem.isCompleted { sleepItem.completedAt = Date() }
        }
    }

    func fetchMonthDays(for date: Date, modelContext: ModelContext) -> [ChecklistDay] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let start = monthInterval.start
        let end = monthInterval.end

        let predicate = #Predicate<ChecklistDay> { day in
            day.date >= start && day.date < end
        }
        let descriptor = FetchDescriptor<ChecklistDay>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
