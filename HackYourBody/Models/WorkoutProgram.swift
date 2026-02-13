import Foundation
import SwiftData

@Model
final class WorkoutProgram {
    var name: String
    var programDescription: String
    var durationWeeks: Int
    var splitType: SplitType
    var startDate: Date
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var sessions: [WorkoutSession]
    var createdAt: Date

    init(
        name: String = "",
        programDescription: String = "",
        durationWeeks: Int = 8,
        splitType: SplitType = .pushPullLegs,
        startDate: Date = .now,
        isActive: Bool = true
    ) {
        self.name = name
        self.programDescription = programDescription
        self.durationWeeks = durationWeeks
        self.splitType = splitType
        self.startDate = startDate
        self.isActive = isActive
        self.sessions = []
        self.createdAt = Date()
    }

    var completedSessions: Int {
        sessions.filter(\.isCompleted).count
    }

    var totalSessions: Int {
        sessions.count
    }

    var progressPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }

    var currentWeek: Int {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max(daysSinceStart / 7 + 1, 1), durationWeeks)
    }
}

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case pushPullLegs = "Push / Pull / Legs"
    case upperLower = "Upper / Lower"
    case fullBody = "Full Body"
    case bro = "Bro Split"
    case custom = "Personnalisé"

    var id: String { rawValue }

    var daysPerCycle: Int {
        switch self {
        case .pushPullLegs: return 6
        case .upperLower: return 4
        case .fullBody: return 3
        case .bro: return 5
        case .custom: return 0
        }
    }

    var icon: String {
        switch self {
        case .pushPullLegs: return "figure.strengthtraining.traditional"
        case .upperLower: return "figure.mixed.cardio"
        case .fullBody: return "figure.run"
        case .bro: return "dumbbell.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}
