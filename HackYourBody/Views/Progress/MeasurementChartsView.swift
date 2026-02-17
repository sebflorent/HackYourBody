import SwiftUI
import SwiftData
import Charts

struct MeasurementChartsView: View {
    @Query(sort: \BodyMeasurement.date)
    private var measurements: [BodyMeasurement]

    @State private var selectedMetric = "Poitrine"

    private let metrics = [
        "Poitrine", "Épaules", "Cou",
        "Biceps G", "Biceps D",
        "Taille", "Hanches",
        "Cuisse G", "Cuisse D",
        "% Graisse"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if measurements.count < 2 {
                    ContentUnavailableView(
                        "Pas assez de données",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Il faut au moins 2 mesures pour voir les graphiques")
                    )
                } else {
                    // Metric picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(metrics, id: \.self) { metric in
                                metricChip(metric)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Selected metric chart
                    selectedMetricChart
                        .padding(.horizontal)

                    // Overview: all muscles on one chart
                    overviewChart
                        .padding(.horizontal)

                    // Body fat chart if data exists
                    if measurements.contains(where: { $0.bodyFatPercent != nil }) {
                        bodyFatChart
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Metric Chip

    private func metricChip(_ metric: String) -> some View {
        Button {
            selectedMetric = metric
        } label: {
            Text(metric)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedMetric == metric ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selectedMetric == metric ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Selected Metric Chart

    private var selectedMetricChart: some View {
        let dataPoints = dataForMetric(selectedMetric)

        return VStack(alignment: .leading, spacing: 12) {
            Text(selectedMetric)
                .font(.headline)

            if dataPoints.count >= 2 {
                let first = dataPoints.first!.value
                let last = dataPoints.last!.value
                let delta = last - first
                HStack {
                    Text("Actuel: \(last.cleanString) \(selectedMetric == "% Graisse" ? "%" : "cm")")
                        .font(.subheadline)
                    Spacer()
                    Text("\(delta >= 0 ? "+" : "")\(delta.cleanString)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(delta >= 0 ? .green : .orange)
                }
            }

            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Valeur", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Valeur", point.value)
                    )
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Valeur", point.value)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 220)
            .chartYAxisLabel(selectedMetric == "% Graisse" ? "%" : "cm")
        }
        .cardStyle()
    }

    // MARK: - Overview Chart (multiple muscles)

    private var overviewChart: some View {
        let muscleMetrics = ["Poitrine", "Biceps D", "Taille", "Cuisse D"]
        let allPoints = muscleMetrics.flatMap { metric in
            dataForMetric(metric).map { MeasurementDataPoint(date: $0.date, value: $0.value, label: metric) }
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Vue d'ensemble")
                .font(.headline)

            if allPoints.isEmpty {
                Text("Pas assez de données")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(allPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("cm", point.value)
                        )
                        .foregroundStyle(by: .value("Mesure", point.label))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 250)
                .chartYAxisLabel("cm")
            }
        }
        .cardStyle()
    }

    // MARK: - Body Fat Chart

    private var bodyFatChart: some View {
        let points = measurements.compactMap { m -> MeasurementDataPoint? in
            guard let bf = m.bodyFatPercent else { return nil }
            return MeasurementDataPoint(date: m.date, value: bf, label: "% Graisse")
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("% Masse grasse")
                .font(.headline)

            Chart {
                ForEach(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("%", point.value)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("%", point.value)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 200)
            .chartYAxisLabel("%")
        }
        .cardStyle()
    }

    // MARK: - Data Extraction

    private func dataForMetric(_ metric: String) -> [MeasurementDataPoint] {
        measurements.compactMap { m in
            let value: Double
            switch metric {
            case "Poitrine": value = m.chestCm
            case "Épaules": value = m.shouldersCm
            case "Cou": value = m.neckCm
            case "Biceps G": value = m.leftBicepCm
            case "Biceps D": value = m.rightBicepCm
            case "Taille": value = m.waistCm
            case "Hanches": value = m.hipsCm
            case "Cuisse G": value = m.leftThighCm
            case "Cuisse D": value = m.rightThighCm
            case "% Graisse": value = m.bodyFatPercent ?? 0
            default: value = 0
            }
            guard value > 0 else { return nil }
            return MeasurementDataPoint(date: m.date, value: value, label: metric)
        }
    }
}
