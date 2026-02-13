import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var label: String
    var icon: String
    var category: ChecklistCategory
    var isCompleted: Bool
    var isAutoFilled: Bool
    var source: String?
    var completedAt: Date?
    var day: ChecklistDay?

    init(
        label: String,
        icon: String = "checkmark.circle",
        category: ChecklistCategory = .health,
        isCompleted: Bool = false,
        isAutoFilled: Bool = false,
        source: String? = nil
    ) {
        self.label = label
        self.icon = icon
        self.category = category
        self.isCompleted = isCompleted
        self.isAutoFilled = isAutoFilled
        self.source = source
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

enum ChecklistCategory: String, Codable, CaseIterable, Identifiable {
    case training = "Entraînement"
    case nutrition = "Nutrition"
    case supplement = "Suppléments"
    case health = "Santé"
    case custom = "Personnalisé"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .training: return "blue"
        case .nutrition: return "green"
        case .supplement: return "purple"
        case .health: return "red"
        case .custom: return "orange"
        }
    }
}
