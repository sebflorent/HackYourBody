import SwiftUI

struct HealthKitSettingsView: View {
    @State private var healthKit = HealthKitService.shared
    @State private var stepsHistory: [(date: Date, steps: Int)] = []
    @State private var newWeight: Double = 0
    @State private var showWeightInput = false

    var body: some View {
        List {
            Section("État de la connexion") {
                HStack {
                    Label("Disponible", systemImage: "checkmark.circle")
                    Spacer()
                    Text(healthKit.isAvailable ? "Oui" : "Non")
                        .foregroundStyle(healthKit.isAvailable ? .green : .red)
                }

                HStack {
                    Label("Autorisé", systemImage: "lock.open")
                    Spacer()
                    Text(healthKit.isAuthorized ? "Oui" : "Non")
                        .foregroundStyle(healthKit.isAuthorized ? .green : .red)
                }

                if !healthKit.isAuthorized {
                    Button("Demander l'autorisation") {
                        Task {
                            try? await healthKit.requestAuthorization()
                        }
                    }
                }
            }

            Section("Données actuelles") {
                DataRow(label: "Pas aujourd'hui", value: "\(healthKit.stepsToday)", icon: "figure.walk", color: .green)
                DataRow(label: "Calories actives", value: "\(Int(healthKit.activeCaloriesToday)) kcal", icon: "flame.fill", color: .orange)
                DataRow(label: "FC repos", value: healthKit.restingHeartRate > 0 ? "\(Int(healthKit.restingHeartRate)) bpm" : "--", icon: "heart.fill", color: .red)
                DataRow(label: "Sommeil", value: healthKit.sleepHoursLastNight > 0 ? String(format: "%.1fh", healthKit.sleepHoursLastNight) : "--", icon: "moon.zzz.fill", color: .indigo)
                DataRow(label: "Poids", value: healthKit.currentWeight > 0 ? "\(healthKit.currentWeight.cleanString) kg" : "--", icon: "scalemass.fill", color: .blue)
            }

            Section("Actions") {
                Button {
                    Task { await healthKit.fetchTodayData() }
                } label: {
                    Label("Rafraîchir les données", systemImage: "arrow.clockwise")
                }

                Button {
                    showWeightInput = true
                } label: {
                    Label("Enregistrer mon poids", systemImage: "scalemass.fill")
                }
            }

            Section("Données synchronisées") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Données lues depuis Health:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    BulletPoint("Pas quotidiens")
                    BulletPoint("Calories actives brûlées")
                    BulletPoint("Fréquence cardiaque au repos")
                    BulletPoint("Durée de sommeil")
                    BulletPoint("Poids corporel")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Données écrites vers Health:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    BulletPoint("Workouts complétés")
                    BulletPoint("Poids corporel")
                }
            }
        }
        .navigationTitle("Apple Health")
        .task {
            await healthKit.fetchTodayData()
        }
        .alert("Enregistrer mon poids", isPresented: $showWeightInput) {
            TextField("Poids en kg", value: $newWeight, format: .number)
                .keyboardType(.decimalPad)
            Button("Sauvegarder") {
                Task {
                    try? await healthKit.saveWeight(newWeight)
                    await healthKit.fetchTodayData()
                }
            }
            Button("Annuler", role: .cancel) { }
        }
    }
}

struct DataRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
        }
    }
}
