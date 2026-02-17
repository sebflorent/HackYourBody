import SwiftUI

struct AddMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var chestCm = ""
    @State private var waistCm = ""
    @State private var hipsCm = ""
    @State private var leftBicepCm = ""
    @State private var rightBicepCm = ""
    @State private var leftThighCm = ""
    @State private var rightThighCm = ""
    @State private var neckCm = ""
    @State private var shouldersCm = ""
    @State private var bodyFatPercent = ""
    @State private var date = Date()

    /// Optionally pre-fill from a previous measurement
    var prefill: BodyMeasurement?

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                }

                Section("Haut du corps") {
                    measurementField("Épaules", value: $shouldersCm, icon: "figure.arms.open")
                    measurementField("Poitrine", value: $chestCm, icon: "figure.stand")
                    measurementField("Cou", value: $neckCm, icon: "person.crop.circle")
                    measurementField("Biceps gauche", value: $leftBicepCm, icon: "figure.strengthtraining.traditional")
                    measurementField("Biceps droit", value: $rightBicepCm, icon: "figure.strengthtraining.traditional")
                }

                Section("Bas du corps") {
                    measurementField("Taille (tour)", value: $waistCm, icon: "figure.stand")
                    measurementField("Hanches", value: $hipsCm, icon: "figure.stand")
                    measurementField("Cuisse gauche", value: $leftThighCm, icon: "figure.walk")
                    measurementField("Cuisse droite", value: $rightThighCm, icon: "figure.walk")
                }

                Section("Composition") {
                    measurementField("% masse grasse", value: $bodyFatPercent, icon: "percent", unit: "%")
                }
            }
            .navigationTitle("Nouvelles mensurations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sauvegarder") {
                        saveMeasurement()
                    }
                    .fontWeight(.bold)
                    .disabled(!hasAnyValue)
                }
            }
            .onAppear {
                if let p = prefill {
                    fillFromPrevious(p)
                }
            }
        }
    }

    // MARK: - Field

    private func measurementField(_ label: String, value: Binding<String>, icon: String, unit: String = "cm") -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Save

    private var hasAnyValue: Bool {
        [chestCm, waistCm, hipsCm, leftBicepCm, rightBicepCm,
         leftThighCm, rightThighCm, neckCm, shouldersCm, bodyFatPercent]
            .contains { !$0.isEmpty && $0 != "0" }
    }

    private func saveMeasurement() {
        let measurement = BodyMeasurement(
            date: date,
            chestCm: parseDouble(chestCm),
            waistCm: parseDouble(waistCm),
            hipsCm: parseDouble(hipsCm),
            leftBicepCm: parseDouble(leftBicepCm),
            rightBicepCm: parseDouble(rightBicepCm),
            leftThighCm: parseDouble(leftThighCm),
            rightThighCm: parseDouble(rightThighCm),
            neckCm: parseDouble(neckCm),
            shouldersCm: parseDouble(shouldersCm),
            bodyFatPercent: parseOptionalDouble(bodyFatPercent)
        )

        modelContext.insert(measurement)
        dismiss()
    }

    private func parseDouble(_ str: String) -> Double {
        Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func parseOptionalDouble(_ str: String) -> Double? {
        let v = parseDouble(str)
        return v > 0 ? v : nil
    }

    private func fillFromPrevious(_ m: BodyMeasurement) {
        if m.chestCm > 0 { chestCm = m.chestCm.cleanString }
        if m.waistCm > 0 { waistCm = m.waistCm.cleanString }
        if m.hipsCm > 0 { hipsCm = m.hipsCm.cleanString }
        if m.leftBicepCm > 0 { leftBicepCm = m.leftBicepCm.cleanString }
        if m.rightBicepCm > 0 { rightBicepCm = m.rightBicepCm.cleanString }
        if m.leftThighCm > 0 { leftThighCm = m.leftThighCm.cleanString }
        if m.rightThighCm > 0 { rightThighCm = m.rightThighCm.cleanString }
        if m.neckCm > 0 { neckCm = m.neckCm.cleanString }
        if m.shouldersCm > 0 { shouldersCm = m.shouldersCm.cleanString }
        if let bf = m.bodyFatPercent { bodyFatPercent = bf.cleanString }
    }
}
