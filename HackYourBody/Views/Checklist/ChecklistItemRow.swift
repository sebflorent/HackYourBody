import SwiftUI

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Check circle
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? Color.green : Color(.systemGray3), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if item.isCompleted {
                        Circle()
                            .fill(.green)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

                // Icon
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundStyle(item.isCompleted ? .green : AppColors.forCategory(item.category))
                    .frame(width: 24)

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted, color: .secondary)

                    if item.isAutoFilled, let source = item.source {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                            Text("Auto: \(source)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Completion time
                if let completedAt = item.completedAt {
                    Text(completedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(item.isCompleted ? Color.green.opacity(0.05) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: item.isCompleted)
    }
}
