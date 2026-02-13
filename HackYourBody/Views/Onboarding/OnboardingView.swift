import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if vm.currentStep != .welcome {
                ProgressView(value: vm.currentStep.progress)
                    .tint(.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // Content
            TabView(selection: Binding(
                get: { vm.currentStep },
                set: { _ in }
            )) {
                WelcomeStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.welcome)

                ProfileStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.profile)

                GoalStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.goal)

                ActivityStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.activity)

                EquipmentStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.equipment)

                DietaryStepView(vm: vm)
                    .tag(OnboardingViewModel.OnboardingStep.dietary)

                SummaryStepView(vm: vm, onComplete: {
                    vm.createProfile(in: modelContext)
                    onComplete()
                })
                .tag(OnboardingViewModel.OnboardingStep.summary)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: vm.currentStep)

            // Navigation buttons
            if vm.currentStep != .welcome && vm.currentStep != .summary {
                HStack {
                    Button {
                        vm.previousStep()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        vm.nextStep()
                    } label: {
                        HStack {
                            Text("Suivant")
                            Image(systemName: "chevron.right")
                        }
                        .fontWeight(.semibold)
                    }
                    .disabled(!vm.canProceed)
                }
                .padding()
            }
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse)

            VStack(spacing: 12) {
                Text("Hack Your Body")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Ton assistant IA pour la recomposition corporelle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "checklist", title: "Checklist quotidienne", subtitle: "Suis tes habitudes chaque jour")
                FeatureRow(icon: "dumbbell.fill", title: "Programmes workout", subtitle: "Générés par IA selon ton profil")
                FeatureRow(icon: "fork.knife", title: "Recettes adaptées", subtitle: "Macros calculées pour tes objectifs")
                FeatureRow(icon: "heart.fill", title: "Apple Health", subtitle: "Synchronise tes données santé")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                vm.nextStep()
            } label: {
                Text("Commencer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Profile Step

struct ProfileStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Ton profil", subtitle: "Ces informations permettent de personnaliser ton programme")

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prénom")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Ton prénom", text: $vm.name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.givenName)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Poids (kg)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("80", value: $vm.weightKg, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Taille (cm)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("178", value: $vm.heightCm, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Âge")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("30", value: $vm.age, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Goal Step

struct GoalStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Ton objectif", subtitle: "Choisis l'objectif qui correspond le mieux")

                VStack(spacing: 12) {
                    ForEach(FitnessGoal.allCases) { goal in
                        GoalCard(goal: goal, isSelected: vm.goal == goal) {
                            withAnimation { vm.goal = goal }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Activity Step

struct ActivityStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Niveau d'activité", subtitle: "En dehors de l'entraînement")

                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases) { level in
                        Button {
                            withAnimation { vm.activityLevel = level }
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if vm.activityLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding()
                            .background(vm.activityLevel == level ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(vm.activityLevel == level ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Text("Jours d'entraînement par semaine")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(2...6, id: \.self) { day in
                            Button {
                                withAnimation { vm.trainingDaysPerWeek = day }
                            } label: {
                                Text("\(day)")
                                    .font(.headline)
                                    .frame(width: 50, height: 50)
                                    .background(vm.trainingDaysPerWeek == day ? Color.accentColor : Color(.secondarySystemBackground))
                                    .foregroundStyle(vm.trainingDaysPerWeek == day ? .white : .primary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Equipment Step

struct EquipmentStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Ton équipement", subtitle: "Sélectionne ce à quoi tu as accès")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    ForEach(AppConstants.Equipment.allCases) { equipment in
                        let isSelected = vm.selectedEquipment.contains(equipment.rawValue)
                        Button {
                            withAnimation {
                                if isSelected {
                                    vm.selectedEquipment.remove(equipment.rawValue)
                                } else {
                                    vm.selectedEquipment.insert(equipment.rawValue)
                                }
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: equipment.icon)
                                    .font(.title2)
                                Text(equipment.rawValue)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                            .foregroundStyle(isSelected ? Color.accentColor : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Dietary Step

struct DietaryStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Préférences alimentaires", subtitle: "Optionnel - aide à personnaliser les recettes")

                VStack(spacing: 12) {
                    ForEach(AppConstants.DietaryPreference.allCases) { pref in
                        let isSelected = vm.selectedDietaryPrefs.contains(pref.rawValue)
                        Button {
                            withAnimation {
                                if isSelected {
                                    vm.selectedDietaryPrefs.remove(pref.rawValue)
                                } else {
                                    vm.selectedDietaryPrefs.insert(pref.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(pref.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding()
                            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Summary Step

struct SummaryStepView: View {
    let vm: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(title: "Résumé", subtitle: "Vérifie que tout est correct")

                let macros = vm.computeMacros()

                VStack(spacing: 16) {
                    SummaryRow(label: "Prénom", value: vm.name)
                    SummaryRow(label: "Poids", value: "\(vm.weightKg.cleanString) kg")
                    SummaryRow(label: "Taille", value: "\(vm.heightCm.cleanString) cm")
                    SummaryRow(label: "Âge", value: "\(vm.age) ans")
                    SummaryRow(label: "Objectif", value: vm.goal.rawValue)
                    SummaryRow(label: "Activité", value: vm.activityLevel.rawValue)
                    SummaryRow(label: "Entraînements", value: "\(vm.trainingDaysPerWeek) jours/sem")

                    Divider()

                    Text("Macros calculées")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        MacroBox(label: "Calories", value: "\(macros.calories)", unit: "kcal", color: .orange)
                        MacroBox(label: "Protéines", value: "\(macros.protein)", unit: "g", color: .red)
                        MacroBox(label: "Glucides", value: "\(macros.carbs)", unit: "g", color: .blue)
                        MacroBox(label: "Lipides", value: "\(macros.fat)", unit: "g", color: .yellow)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    onComplete()
                } label: {
                    Text("C'est parti !")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Helper Views

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct MacroBox: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
