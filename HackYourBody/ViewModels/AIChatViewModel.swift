import Foundation
import SwiftData

@MainActor @Observable
final class AIChatViewModel {
    private let aiService = AIService.shared

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading = false

    func loadMessages(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    func sendMessage(profile: UserProfile?, modelContext: ModelContext) async {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: userText)
        modelContext.insert(userMessage)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        do {
            // Build conversation context
            var apiMessages: [(role: String, content: String)] = [
                (role: "system", content: buildSystemPrompt(profile: profile))
            ]

            // Include recent messages for context (last 20)
            let recentMessages = messages.suffix(20)
            for msg in recentMessages {
                apiMessages.append((role: msg.role.rawValue, content: msg.content))
            }

            let response = try await aiService.chat(messages: apiMessages)

            let assistantMessage = ChatMessage(role: .assistant, content: response)
            modelContext.insert(assistantMessage)
            messages.append(assistantMessage)
            isLoading = false
        } catch {
            let errorMsg = ChatMessage(role: .assistant, content: "Erreur: \(error.localizedDescription)")
            modelContext.insert(errorMsg)
            messages.append(errorMsg)
            isLoading = false
        }
    }

    func clearHistory(modelContext: ModelContext) {
        for message in messages {
            modelContext.delete(message)
        }
        messages = []
    }

    private func buildSystemPrompt(profile: UserProfile?) -> String {
        var prompt = """
        Tu es un assistant coach sportif et nutritionniste expert, spécialisé en recomposition corporelle.
        Tu parles en français de manière naturelle et motivante.
        Tu donnes des conseils pratiques et personnalisés.
        Tu peux aider avec: les programmes d'entraînement, la nutrition, les suppléments, la récupération, la motivation.
        Sois concis mais complet dans tes réponses.
        """

        if let profile {
            prompt += """

            Profil de l'utilisateur:
            - Prénom: \(profile.name)
            - Poids: \(profile.weightKg)kg, Taille: \(profile.heightCm)cm, Âge: \(profile.age) ans
            - Objectif: \(profile.goal.rawValue)
            - Activité: \(profile.activityLevel.rawValue)
            - Entraînements: \(profile.trainingDaysPerWeek) jours/semaine
            - Équipement: \(profile.equipmentAvailable.joined(separator: ", "))
            - Préférences alimentaires: \(profile.dietaryPreferences.joined(separator: ", ").isEmpty ? "Aucune" : profile.dietaryPreferences.joined(separator: ", "))
            - Macros cibles: \(profile.dailyCalorieTarget) kcal, P:\(profile.dailyProteinTargetG)g G:\(profile.dailyCarbsTargetG)g L:\(profile.dailyFatTargetG)g
            """
        }

        return prompt
    }
}
