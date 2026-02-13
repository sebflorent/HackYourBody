import SwiftUI
import SwiftData

struct ChecklistHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let vm: ChecklistViewModel

    @State private var currentMonth: Date = .now
    @State private var monthDays: [ChecklistDay] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.headline)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                calendarGrid

                // Stats
                statsSection

                Spacer()
            }
            .padding()
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear { loadMonth() }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let startWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (startWeekday + 5) % 7 // Monday = 0

        return VStack(spacing: 4) {
            // Weekday headers
            HStack {
                ForEach(["L", "M", "M", "J", "V", "S", "D"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Empty cells before first day
                ForEach(0..<offset, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                // Day cells
                ForEach(Array(daysInMonth), id: \.self) { dayNum in
                    let date = calendar.date(bySetting: .day, value: dayNum, of: firstDay)!
                    let dayData = monthDays.first { calendar.isDate($0.date, inSameDayAs: date) }

                    DayCell(
                        day: dayNum,
                        compliance: dayData?.complianceScore,
                        isToday: calendar.isDateInToday(date)
                    )
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        let completeDays = monthDays.filter { $0.complianceScore >= 0.8 }.count
        let avgCompliance = monthDays.isEmpty ? 0 : monthDays.reduce(0.0) { $0 + $1.complianceScore } / Double(monthDays.count)

        return VStack(spacing: 12) {
            Text("Statistiques du mois")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                StatBox(label: "Jours actifs", value: "\(monthDays.count)", color: .blue)
                StatBox(label: "Jours > 80%", value: "\(completeDays)", color: .green)
                StatBox(label: "Compliance moy.", value: "\(Int(avgCompliance * 100))%", color: .orange)
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
            loadMonth()
        }
    }

    private func loadMonth() {
        monthDays = vm.fetchMonthDays(for: currentMonth, modelContext: modelContext)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let day: Int
    let compliance: Double?
    let isToday: Bool

    var body: some View {
        ZStack {
            if let compliance {
                Circle()
                    .fill(colorForCompliance(compliance))
                    .frame(width: 32, height: 32)
            }

            Text("\(day)")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(compliance != nil ? .white : .primary)
        }
        .frame(height: 36)
        .overlay {
            if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 34, height: 34)
            }
        }
    }

    private func colorForCompliance(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        case 0.01..<0.5: return .red.opacity(0.6)
        default: return .gray.opacity(0.3)
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
