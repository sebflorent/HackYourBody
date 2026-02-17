import SwiftUI
import SwiftData

struct MeasurementListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @State private var showAddMeasurement = false
    @State private var showCharts = false
    @State private var selectedMeasurement: BodyMeasurement?
    @State private var showDeleteConfirm = false
    @State private var measurementToDelete: BodyMeasurement?

    var body: some View {
        VStack(spacing: 0) {
            if measurements.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Pas encore de mensurations",
                    systemImage: "ruler",
                    description: Text("Ajoute tes premières mensurations pour suivre ta progression")
                )
                Spacer()
            } else {
                // Latest measurement summary
                if let latest = measurements.first {
                    latestSummaryCard(latest)
                        .padding()
                }

                // Delta card if 2+ measurements
                if measurements.count >= 2 {
                    deltaCard(latest: measurements[0], previous: measurements[1])
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }

                // History list
                List {
                    ForEach(measurements) { measurement in
                        measurementRow(measurement)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    measurementToDelete = measurement
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementView(prefill: measurements.first)
        }
        .confirmationDialog("Supprimer cette mesure ?", isPresented: $showDeleteConfirm) {
            Button("Supprimer", role: .destructive) {
                if let m = measurementToDelete {
                    modelContext.delete(m)
                }
            }
            Button("Annuler", role: .cancel) { }
        }
    }

    // MARK: - Latest Summary

    private func latestSummaryCard(_ m: BodyMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "ruler")
                    .foregroundStyle(.blue)
                Text("Dernières mensurations")
                    .font(.headline)
                Spacer()
                Text(m.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let items = m.nonZeroMeasurements
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(items, id: \.label) { item in
                    VStack(spacing: 2) {
                        Text(item.value.cleanString)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(item.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let bf = m.bodyFatPercent {
                HStack {
                    Image(systemName: "percent")
                        .foregroundStyle(.orange)
                    Text("Masse grasse: \(bf.cleanString)%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let ratio = m.waistToHipRatio {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.purple)
                    Text("Ratio taille/hanches: \(String(format: "%.2f", ratio))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Delta Card

    private func deltaCard(latest: BodyMeasurement, previous: BodyMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.swap")
                    .foregroundStyle(.green)
                Text("Évolution depuis le \(previous.date.dayMonth)")
                    .font(.caption)
                    .fontWeight(.bold)
            }

            let deltas = computeDeltas(latest: latest, previous: previous)
            if deltas.isEmpty {
                Text("Pas de changement mesurable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(deltas, id: \.label) { d in
                        HStack(spacing: 4) {
                            Image(systemName: d.delta > 0 ? "arrow.up.right" : (d.delta < 0 ? "arrow.down.right" : "equal"))
                                .font(.caption2)
                                .foregroundStyle(deltaColor(d.delta, isWaist: d.label == "Taille"))
                            Text(d.label)
                                .font(.caption2)
                            Spacer()
                            Text("\(d.delta >= 0 ? "+" : "")\(d.delta.cleanString) cm")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(deltaColor(d.delta, isWaist: d.label == "Taille"))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Measurement Row

    private func measurementRow(_ m: BodyMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(m.date.shortFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(m.nonZeroMeasurements.count) mesures")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(m.nonZeroMeasurements.prefix(4), id: \.label) { item in
                    VStack(spacing: 1) {
                        Text(item.value.cleanString)
                            .font(.caption)
                            .fontWeight(.bold)
                        Text(item.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private struct DeltaItem {
        let label: String
        let delta: Double
    }

    private func computeDeltas(latest: BodyMeasurement, previous: BodyMeasurement) -> [DeltaItem] {
        var results: [DeltaItem] = []
        func add(_ label: String, _ l: Double, _ p: Double) {
            if l > 0, p > 0 {
                let d = l - p
                if abs(d) > 0.01 { results.append(DeltaItem(label: label, delta: d)) }
            }
        }
        add("Poitrine", latest.chestCm, previous.chestCm)
        add("Épaules", latest.shouldersCm, previous.shouldersCm)
        add("Biceps G", latest.leftBicepCm, previous.leftBicepCm)
        add("Biceps D", latest.rightBicepCm, previous.rightBicepCm)
        add("Taille", latest.waistCm, previous.waistCm)
        add("Hanches", latest.hipsCm, previous.hipsCm)
        add("Cuisse G", latest.leftThighCm, previous.leftThighCm)
        add("Cuisse D", latest.rightThighCm, previous.rightThighCm)
        return results
    }

    private func deltaColor(_ delta: Double, isWaist: Bool) -> Color {
        if abs(delta) < 0.01 { return .secondary }
        // For waist: decrease is good; for muscles: increase is good
        if isWaist {
            return delta < 0 ? .green : .orange
        } else {
            return delta > 0 ? .green : .orange
        }
    }
}
