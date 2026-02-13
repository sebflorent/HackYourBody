import SwiftUI

struct ChecklistProgressCard: View {
    let checklist: ChecklistDay

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(Color.accentColor)
                Text("Checklist du jour")
                    .font(.headline)
                Spacer()
                Text("\(checklist.completedCount)/\(checklist.totalCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: checklist.complianceScore)
                .tint(complianceColor)

            HStack {
                Text("\(Int(checklist.complianceScore * 100))% complété")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if checklist.complianceScore >= 1.0 {
                    Label("Parfait !", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            // Quick preview of pending items
            let pendingItems = checklist.items.filter { !$0.isCompleted }.prefix(3)
            if !pendingItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(pendingItems)) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var complianceColor: Color {
        switch checklist.complianceScore {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}
