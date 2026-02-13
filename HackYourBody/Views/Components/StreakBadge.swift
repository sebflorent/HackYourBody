import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) jour\(streak > 1 ? "s" : "") consécutif\(streak > 1 ? "s" : "")")
                    .font(.headline)
                Text("Continue comme ça !")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(streakEmoji)
                .font(.title)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.08), .yellow.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var streakEmoji: String {
        switch streak {
        case 1...6: return "🔥"
        case 7...13: return "💪"
        case 14...29: return "⭐️"
        case 30...99: return "🏆"
        default: return "👑"
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 8, color: Color = .accentColor, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
