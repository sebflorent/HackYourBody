import Foundation

// MARK: - AI Service (OpenAI API)

@MainActor @Observable
final class AIService {
    static let shared = AIService()

    var isLoading = false

    // Store API key securely - for personal use, set via Settings
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }

    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let generationModel = "gpt-4o-mini"  // Programmes, recettes, suggestions
    private let chatModel = "gpt-4o"              // Chat libre, conseils personnalises

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }

    // MARK: - Generate Workout Program

    func generateWorkoutProgram(profile: UserProfile) async throws -> WorkoutProgramDTO {
        let systemPrompt = """
        Tu es un coach sportif expert en musculation et recomposition corporelle.
        Tu génères des programmes d'entraînement structurés au format JSON.
        Adapte le programme au profil de l'utilisateur.
        Réponds UNIQUEMENT avec du JSON valide, sans texte additionnel.
        """

        let userPrompt = """
        Génère un programme d'entraînement avec ces paramètres:
        - Objectif: \(profile.goal.rawValue)
        - Poids: \(profile.weightKg)kg, Taille: \(profile.heightCm)cm, Âge: \(profile.age) ans
        - Jours d'entraînement/semaine: \(profile.trainingDaysPerWeek)
        - Équipement: \(profile.equipmentAvailable.joined(separator: ", "))
        - Niveau: intermédiaire

        Format JSON attendu:
        {
            "name": "Nom du programme",
            "description": "Description courte",
            "durationWeeks": 8,
            "splitType": "pushPullLegs|upperLower|fullBody|bro|custom",
            "sessions": [
                {
                    "dayNumber": 1,
                    "name": "Push - Pecs / Épaules / Triceps",
                    "muscleGroups": ["Pectoraux", "Épaules", "Triceps"],
                    "exercises": [
                        {
                            "exerciseName": "Développé couché",
                            "muscleGroup": "Pectoraux",
                            "sets": 4,
                            "targetReps": 8,
                            "weightKg": 0,
                            "restSeconds": 120,
                            "notes": "Contrôle la descente sur 3 secondes"
                        }
                    ]
                }
            ]
        }
        """

        let response = try await sendChatRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        let data = Data(response.utf8)
        return try JSONDecoder().decode(WorkoutProgramDTO.self, from: data)
    }

    // MARK: - Generate Recipes

    func generateRecipes(profile: UserProfile, mealType: MealType, count: Int = 3) async throws -> [RecipeDTO] {
        let systemPrompt = """
        Tu es un nutritionniste expert en alimentation sportive et recomposition corporelle.
        Tu génères des recettes adaptées aux objectifs macro de l'utilisateur.
        Réponds UNIQUEMENT avec du JSON valide, sans texte additionnel.
        """

        let userPrompt = """
        Génère \(count) recettes pour: \(mealType.rawValue)
        - Objectif: \(profile.goal.rawValue)
        - Calories cibles/jour: \(profile.dailyCalorieTarget) kcal
        - Protéines cibles/jour: \(profile.dailyProteinTargetG)g
        - Préférences: \(profile.dietaryPreferences.joined(separator: ", ").isEmpty ? "Aucune" : profile.dietaryPreferences.joined(separator: ", "))

        Format JSON attendu (tableau):
        [
            {
                "name": "Nom de la recette",
                "description": "Description courte",
                "mealType": "\(mealType.rawValue)",
                "prepTimeMinutes": 15,
                "cookTimeMinutes": 20,
                "servings": 1,
                "calories": 450,
                "proteinG": 40,
                "carbsG": 35,
                "fatG": 15,
                "ingredients": [
                    {"name": "Poulet", "quantity": 200, "unit": "g"}
                ],
                "steps": ["Étape 1...", "Étape 2..."],
                "tags": ["high-protein", "rapide"]
            }
        ]
        """

        let response = try await sendChatRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        let data = Data(response.utf8)
        return try JSONDecoder().decode([RecipeDTO].self, from: data)
    }

    // MARK: - Generate Meal Plan

    func generateMealPlan(profile: UserProfile) async throws -> MealPlanDTO {
        let systemPrompt = """
        Tu es un nutritionniste expert. Génère un plan alimentaire journalier complet.
        Réponds UNIQUEMENT avec du JSON valide.
        """

        let userPrompt = """
        Génère un plan alimentaire pour une journée complète:
        - Objectif: \(profile.goal.rawValue)
        - Calories: \(profile.dailyCalorieTarget) kcal
        - Protéines: \(profile.dailyProteinTargetG)g | Glucides: \(profile.dailyCarbsTargetG)g | Lipides: \(profile.dailyFatTargetG)g
        - Préférences: \(profile.dietaryPreferences.joined(separator: ", ").isEmpty ? "Aucune" : profile.dietaryPreferences.joined(separator: ", "))

        Format JSON:
        {
            "meals": [
                {
                    "mealType": "Petit-déjeuner",
                    "recipe": {
                        "name": "...",
                        "description": "...",
                        "mealType": "Petit-déjeuner",
                        "prepTimeMinutes": 10,
                        "cookTimeMinutes": 5,
                        "servings": 1,
                        "calories": 500,
                        "proteinG": 35,
                        "carbsG": 50,
                        "fatG": 18,
                        "ingredients": [{"name": "Oeufs", "quantity": 3, "unit": ""}],
                        "steps": ["..."],
                        "tags": ["high-protein"]
                    }
                }
            ]
        }
        """

        let response = try await sendChatRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        let data = Data(response.utf8)
        return try JSONDecoder().decode(MealPlanDTO.self, from: data)
    }

    // MARK: - Chat

    func chat(messages: [(role: String, content: String)]) async throws -> String {
        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        return try await sendChatRequestRaw(messages: apiMessages, model: chatModel)
    }

    // MARK: - Checklist Suggestion

    func suggestChecklistItems(profile: UserProfile, currentItems: [String]) async throws -> [String] {
        let systemPrompt = """
        Tu es un coach santé. Suggère des items de checklist quotidienne personnalisés.
        Réponds avec un tableau JSON de strings uniquement.
        """

        let userPrompt = """
        Profil: \(profile.goal.rawValue), \(profile.trainingDaysPerWeek) jours/semaine
        Items actuels: \(currentItems.joined(separator: ", "))
        Suggère 3 nouveaux items pertinents. Format: ["item1", "item2", "item3"]
        """

        let response = try await sendChatRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        let data = Data(response.utf8)
        return try JSONDecoder().decode([String].self, from: data)
    }

    // MARK: - Progressive Overload Suggestion

    func suggestProgressiveOverload(exerciseName: String, history: [(weight: Double, reps: Int)]) async throws -> String {
        let systemPrompt = "Tu es un coach musculation. Donne un conseil court et actionnable."

        let historyStr = history.map { "\($0.weight)kg x \($0.reps) reps" }.joined(separator: ", ")
        let userPrompt = """
        Exercice: \(exerciseName)
        Historique récent: \(historyStr)
        Suggère la prochaine progression (poids ou reps). Réponds en 1-2 phrases max.
        """

        return try await sendChatRequest(systemPrompt: systemPrompt, userPrompt: userPrompt, model: chatModel)
    }

    // MARK: - Private API Call

    private func sendChatRequest(systemPrompt: String, userPrompt: String, model: String? = nil) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        return try await sendChatRequestRaw(messages: messages, model: model)
    }

    private func sendChatRequestRaw(messages: [[String: String]], model: String? = nil) async throws -> String {
        guard isConfigured else {
            throw AIError.apiKeyMissing
        }

        isLoading = true
        defer { isLoading = false }

        let selectedModel = model ?? generationModel

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        // Clean the response - remove markdown code blocks if present
        return content
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```\n", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - OpenAI Response Models

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

// MARK: - DTOs for AI-generated content

struct WorkoutProgramDTO: Codable {
    let name: String
    let description: String
    let durationWeeks: Int
    let splitType: String
    let sessions: [SessionDTO]

    struct SessionDTO: Codable {
        let dayNumber: Int
        let name: String
        let muscleGroups: [String]
        let exercises: [ExerciseDTO]
    }

    struct ExerciseDTO: Codable {
        let exerciseName: String
        let muscleGroup: String
        let sets: Int
        let targetReps: Int
        let weightKg: Double
        let restSeconds: Int
        let notes: String?
    }
}

struct RecipeDTO: Codable {
    let name: String
    let description: String
    let mealType: String
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let ingredients: [IngredientDTO]
    let steps: [String]
    let tags: [String]

    struct IngredientDTO: Codable {
        let name: String
        let quantity: Double
        let unit: String
    }
}

struct MealPlanDTO: Codable {
    let meals: [MealDTO]

    struct MealDTO: Codable {
        let mealType: String
        let recipe: RecipeDTO
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case emptyResponse
    case apiError(statusCode: Int, message: String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Clé API OpenAI non configurée. Allez dans Profil > Paramètres pour la saisir."
        case .invalidResponse:
            return "Réponse invalide du serveur."
        case .emptyResponse:
            return "Réponse vide du serveur."
        case .apiError(let code, let message):
            return "Erreur API (\(code)): \(message)"
        case .decodingError(let detail):
            return "Erreur de décodage: \(detail)"
        }
    }
}
