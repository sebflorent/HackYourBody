import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showAPIKeyAlert = false
    @State private var apiKeyInput = ""
    @State private var showEditProfile = false

    private var profile: UserProfile? { profiles.first }
    private let healthKit = HealthKitService.shared
    private let aiService = AIService.shared

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                if let profile {
                    Section("Mon profil") {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                Text(profile.name.prefix(1).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.accentColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                Text("\(profile.weightKg.cleanString) kg - \(Int(profile.heightCm)) cm - \(profile.age) ans")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(profile.goal.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)

                        Button("Modifier le profil") {
                            showEditProfile = true
                        }
                    }

                    // Macros section
                    Section("Objectifs nutritionnels") {
                        HStack {
                            MacroRow(label: "Calories", value: "\(profile.dailyCalorieTarget)", unit: "kcal", color: .orange)
                        }
                        HStack {
                            MacroRow(label: "Protéines", value: "\(profile.dailyProteinTargetG)", unit: "g", color: .red)
                        }
                        HStack {
                            MacroRow(label: "Glucides", value: "\(profile.dailyCarbsTargetG)", unit: "g", color: .blue)
                        }
                        HStack {
                            MacroRow(label: "Lipides", value: "\(profile.dailyFatTargetG)", unit: "g", color: .yellow)
                        }
                    }
                }

                // HealthKit section
                Section("Apple Health") {
                    HStack {
                        Label("HealthKit", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        if healthKit.isAuthorized {
                            Text("Connecté")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Button("Connecter") {
                                Task {
                                    try? await healthKit.requestAuthorization()
                                }
                            }
                            .font(.caption)
                        }
                    }

                    NavigationLink {
                        HealthKitSettingsView()
                    } label: {
                        Label("Paramètres Health", systemImage: "gearshape")
                    }
                }

                // AI section
                Section("Intelligence Artificielle") {
                    HStack {
                        Label("API OpenAI", systemImage: "brain")
                            .foregroundStyle(.purple)
                        Spacer()
                        if aiService.isConfigured {
                            Text("Configurée")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("Non configurée")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Button {
                        showAPIKeyAlert = true
                    } label: {
                        Label(aiService.isConfigured ? "Modifier la clé API" : "Configurer la clé API", systemImage: "key")
                    }
                }

                // Navigation
                Section("Plus") {
                    NavigationLink {
                        StatsView()
                    } label: {
                        Label("Statistiques globales", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        AIChatView()
                    } label: {
                        Label("Chat IA", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profil")
            .alert("Clé API OpenAI", isPresented: $showAPIKeyAlert) {
                SecureField("sk-...", text: $apiKeyInput)
                Button("Sauvegarder") {
                    aiService.setAPIKey(apiKeyInput)
                    apiKeyInput = ""
                }
                Button("Annuler", role: .cancel) { apiKeyInput = "" }
            } message: {
                Text("Entre ta clé API OpenAI pour activer la génération IA")
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    EditProfileView(profile: profile)
                }
            }
        }
    }
}

struct MacroRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
            Spacer()
            Text("\(value) \(unit)")
                .fontWeight(.medium)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Prénom", text: $profile.name)
                    HStack {
                        Text("Poids (kg)")
                        Spacer()
                        TextField("80", value: $profile.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Taille (cm)")
                        Spacer()
                        TextField("178", value: $profile.heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Âge")
                        Spacer()
                        TextField("30", value: $profile.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Objectif") {
                    Picker("Objectif", selection: $profile.goal) {
                        ForEach(FitnessGoal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }

                    Picker("Activité", selection: $profile.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Stepper("Entraînements: \(profile.trainingDaysPerWeek) jours/sem",
                            value: $profile.trainingDaysPerWeek, in: 2...6)
                }

                Section("Macros quotidiennes") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("2200", value: $profile.dailyCalorieTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Protéines (g)")
                        Spacer()
                        TextField("160", value: $profile.dailyProteinTargetG, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Glucides (g)")
                        Spacer()
                        TextField("220", value: $profile.dailyCarbsTargetG, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Lipides (g)")
                        Spacer()
                        TextField("70", value: $profile.dailyFatTargetG, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") {
                        profile.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
    }
}
