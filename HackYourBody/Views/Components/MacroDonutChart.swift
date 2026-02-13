import SwiftUI
import Charts

struct MacroDonutChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double

    var body: some View {
        VStack(spacing: 12) {
            Chart {
                SectorMark(
                    angle: .value("Protéines", protein * 4),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.red)

                SectorMark(
                    angle: .value("Glucides", carbs * 4),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.blue)

                SectorMark(
                    angle: .value("Lipides", fat * 9),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.yellow)
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry[chartProxy.plotFrame!]
                    VStack(spacing: 2) {
                        Text("\(Int(calories))")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(height: 140)

            HStack(spacing: 16) {
                MacroLegend(color: .red, label: "P", value: "\(Int(protein))g")
                MacroLegend(color: .blue, label: "G", value: "\(Int(carbs))g")
                MacroLegend(color: .yellow, label: "L", value: "\(Int(fat))g")
            }
        }
    }
}

struct MacroLegend: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
