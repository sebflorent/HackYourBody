import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \ChecklistDay.date, order: .reverse)
    private var allChecklistDays: [ChecklistDay]
    @Query(filter: #Predicate<WorkoutProgram> { $0.isActive })
    private var activePrograms: [WorkoutProgram]

    @State private var vm = DashboardViewModel()

    private var profile: UserProfile? { profiles.first }
    private var todayChecklist: ChecklistDay? {
        allChecklistDays.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    greetingSection

                    // Streak badge
                    if vm.streak > 0 {
                        StreakBadge(streak: vm.streak)
                    }

                    // Checklist progress
                    if let checklist = todayChecklist {
                        ChecklistProgressCard(checklist: checklist)
                    }

                    // Today's workout
                    if let program = activePrograms.first {
                        WorkoutOfDayCard(program: program)
                    }

                    // Body progress summary
                    ProgressSummaryCard()

                    // HealthKit summary
                    HealthKitSummaryCard(
                        steps: vm.stepsToday,
                        activeCalories: vm.activeCalories,
                        heartRate: vm.restingHeartRate,
                        sleepHours: vm.sleepHours,
                        weight: vm.currentWeight
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .task {
                await vm.loadData(modelContext: modelContext)
            }
            .refreshable {
                await vm.loadData(modelContext: modelContext)
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(Date().dayOfWeek + " " + Date().dayMonth)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile?.name ?? ""
        let greeting: String
        switch hour {
        case 5..<12: greeting = "Bonjour"
        case 12..<18: greeting = "Bon après-midi"
        default: greeting = "Bonsoir"
        }
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }
}

