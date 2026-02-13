import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = ChecklistViewModel()
    @State private var todayChecklist: ChecklistDay?
    @State private var showAddItem = false
    @State private var newItemLabel = ""
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date selector
                    dateSelector

                    // Compliance score
                    if let day = todayChecklist {
                        complianceHeader(day: day)
                    }

                    // Items grouped by category
                    if let day = todayChecklist {
                        checklistItems(day: day)
                    }
                }
                .padding()
            }
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "calendar")
                        }

                        Button {
                            showAddItem = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                ChecklistHistoryView(vm: vm)
            }
            .alert("Nouvel objectif", isPresented: $showAddItem) {
                TextField("Ex: Méditation 10 min", text: $newItemLabel)
                Button("Ajouter") {
                    if let day = todayChecklist, !newItemLabel.isEmpty {
                        vm.addCustomItem(label: newItemLabel, to: day, modelContext: modelContext)
                        newItemLabel = ""
                    }
                }
                Button("Annuler", role: .cancel) { newItemLabel = "" }
            }
            .onAppear { loadChecklist() }
            .onChange(of: vm.selectedDate) { _, _ in loadChecklist() }
            .task {
                if let day = todayChecklist {
                    await vm.updateHealthKitItems(day: day)
                }
            }
        }
    }

    private func loadChecklist() {
        todayChecklist = vm.getOrCreateToday(modelContext: modelContext)
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)

                    Button {
                        withAnimation { vm.selectedDate = date }
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayLetter(date))
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white : .secondary)
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.headline)
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .frame(width: 44, height: 60)
                        .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(3).uppercased()
    }

    // MARK: - Compliance Header

    private func complianceHeader(day: ChecklistDay) -> some View {
        HStack(spacing: 20) {
            ProgressRing(
                progress: day.complianceScore,
                lineWidth: 10,
                color: complianceColor(day.complianceScore),
                size: 70
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(day.completedCount) sur \(day.totalCount)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(complianceMessage(day.complianceScore))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .cardStyle()
    }

    private func complianceColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    private func complianceMessage(_ score: Double) -> String {
        switch score {
        case 1.0: return "Journée parfaite !"
        case 0.8..<1.0: return "Presque parfait, continue !"
        case 0.5..<0.8: return "Bonne progression, encore un effort !"
        default: return "Allez, on s'y met !"
        }
    }

    // MARK: - Checklist Items

    private func checklistItems(day: ChecklistDay) -> some View {
        let grouped = Dictionary(grouping: day.items, by: \.category)
        let sortedCategories = ChecklistCategory.allCases.filter { grouped[$0] != nil }

        return ForEach(sortedCategories) { category in
            VStack(alignment: .leading, spacing: 8) {
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.forCategory(category))

                ForEach(grouped[category] ?? []) { item in
                    ChecklistItemRow(item: item) {
                        withAnimation(.spring(response: 0.3)) {
                            item.toggle()
                        }
                    }
                }
            }
        }
    }
}
