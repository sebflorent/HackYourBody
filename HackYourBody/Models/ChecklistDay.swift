import Foundation
import SwiftData

@Model
final class ChecklistDay {
    var date: Date
    @Relationship(deleteRule: .cascade) var items: [ChecklistItem]

    init(date: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.items = []
    }

    var complianceScore: Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter(\.isCompleted).count
        return Double(completed) / Double(items.count)
    }

    var completedCount: Int {
        items.filter(\.isCompleted).count
    }

    var totalCount: Int {
        items.count
    }

    static func defaultItems() -> [ChecklistItem] {
        [
            ChecklistItem(label: "Entraînement du jour", icon: "figure.run", category: .training),
            ChecklistItem(label: "Objectif protéines (160g)", icon: "fork.knife", category: .nutrition),
            ChecklistItem(label: "Objectif calories respecté", icon: "flame.fill", category: .nutrition),
            ChecklistItem(label: "Créatine (5g)", icon: "pill.fill", category: .supplement),
            ChecklistItem(label: "Hydratation (3L)", icon: "drop.fill", category: .health),
            ChecklistItem(label: "Sommeil 7h+", icon: "moon.zzz.fill", category: .health, isAutoFilled: true, source: "HealthKit"),
            ChecklistItem(label: "10 000 pas", icon: "figure.walk", category: .health, isAutoFilled: true, source: "HealthKit"),
            ChecklistItem(label: "Stretching / Mobilité", icon: "figure.flexibility", category: .training),
        ]
    }
}
