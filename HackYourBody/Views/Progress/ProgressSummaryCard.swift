import SwiftUI
import SwiftData

struct ProgressSummaryCard: View {
    @Query(sort: \ProgressPhoto.date, order: .reverse)
    private var photos: [ProgressPhoto]

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    private var latestPhoto: ProgressPhoto? { photos.first }
    private var latestMeasurement: BodyMeasurement? { measurements.first }

    private var hasData: Bool {
        latestPhoto != nil || latestMeasurement != nil
    }

    var body: some View {
        if hasData {
            NavigationLink {
                ProgressTabView()
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.crop.rectangle.stack")
                            .foregroundStyle(.purple)
                        Text("Suivi corporel")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        // Latest photo thumbnail
                        if let photo = latestPhoto, let uiImage = photo.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            // Photo count
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(photos.count) photos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Measurement highlights
                            if let m = latestMeasurement {
                                let items = m.nonZeroMeasurements.prefix(3)
                                ForEach(items, id: \.label) { item in
                                    HStack(spacing: 4) {
                                        Text(item.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("\(item.value.cleanString) cm")
                                            .font(.caption2)
                                            .fontWeight(.bold)

                                        // Show delta if 2+ measurements
                                        if measurements.count >= 2 {
                                            let prev = measurements[1]
                                            let delta = deltaFor(label: item.label, latest: m, previous: prev)
                                            if abs(delta) > 0.01 {
                                                Text("(\(delta >= 0 ? "+" : "")\(delta.cleanString))")
                                                    .font(.caption2)
                                                    .foregroundStyle(delta >= 0 ? .green : .orange)
                                            }
                                        }
                                    }
                                }
                            }

                            if let m = latestMeasurement {
                                Text("Mis à jour le \(m.date.dayMonth)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }

    private func deltaFor(label: String, latest: BodyMeasurement, previous: BodyMeasurement) -> Double {
        switch label {
        case "Poitrine": return latest.chestCm - previous.chestCm
        case "Épaules": return latest.shouldersCm - previous.shouldersCm
        case "Cou": return latest.neckCm - previous.neckCm
        case "Biceps G": return latest.leftBicepCm - previous.leftBicepCm
        case "Biceps D": return latest.rightBicepCm - previous.rightBicepCm
        case "Taille": return latest.waistCm - previous.waistCm
        case "Hanches": return latest.hipsCm - previous.hipsCm
        case "Cuisse G": return latest.leftThighCm - previous.leftThighCm
        case "Cuisse D": return latest.rightThighCm - previous.rightThighCm
        default: return 0
        }
    }
}
