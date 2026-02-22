import Foundation
import Combine

enum LoadState {
    case loading
    case loaded(recipe: Recipe, ingredients: [DisplayIngredient])
    case noRecipe(String)
    case error(String)
}

@MainActor
class WeekPlanService: ObservableObject {
    nonisolated private let baseURL: String = {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, !url.isEmpty else {
            fatalError("API_BASE_URL not set. Copy Config.xcconfig.example to Config.xcconfig and fill in your server URL.")
        }
        return url
    }()

    @Published var state: LoadState = .loading

    func load() async {
        do {
            async let ingredientsData = fetch([Ingredient].self, from: "\(baseURL)/ingredients")
            async let recipesData     = fetch([Recipe].self,     from: "\(baseURL)/recipes")
            async let patternsData    = fetch([Pattern].self,    from: "\(baseURL)/patterns")
            async let settingsData    = fetch(Settings.self,     from: "\(baseURL)/settings")

            let (ingredients, recipes, patterns, settings) = try await (
                ingredientsData, recipesData, patternsData, settingsData
            )

            state = resolveToday(
                ingredients: ingredients,
                recipes: recipes,
                patterns: patterns,
                settings: settings
            )
        } catch {
            state = .error("Failed to load: \(error.localizedDescription)")
        }
    }

    nonisolated private func fetch<T: Decodable>(_ type: T.Type, from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func resolveToday(
        ingredients: [Ingredient],
        recipes: [Recipe],
        patterns: [Pattern],
        settings: Settings
    ) -> LoadState {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        guard let startDate = formatter.date(from: settings.patternStartDate) else {
            return .error("Invalid patternStartDate")
        }

        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())

        guard let daysFromStart = calendar.dateComponents([.day], from: start, to: today).day else {
            return .error("Could not compute days from start")
        }

        let weekNumber = daysFromStart / 7
        guard !settings.patternOrder.isEmpty else {
            return .noRecipe("No patterns configured")
        }
        let patternId = settings.patternOrder[weekNumber % settings.patternOrder.count]
        guard let pattern = patterns.first(where: { $0.id == patternId }) else {
            return .noRecipe("No recipe planned for today")
        }

        let weekday = calendar.component(.weekday, from: today)
        let todayDayIndex = (weekday + 5) % 7

        guard let block = pattern.mealBlocks.first(where: { b in
            todayDayIndex >= b.startDayIndex && todayDayIndex < b.startDayIndex + b.durationDays
        }) else {
            return .noRecipe("No recipe planned for today")
        }

        guard let recipe = recipes.first(where: { $0.id == block.recipeId }) else {
            return .noRecipe("Recipe not found")
        }

        let ingredientMap = Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id, $0) })
        let displayIngredients: [DisplayIngredient] = recipe.ingredients.compactMap { ri in
            guard let ing = ingredientMap[ri.ingredientId] else { return nil }
            return DisplayIngredient(id: ri.ingredientId, name: ing.name, quantity: ri.quantity, unit: ri.unit)
        }

        return .loaded(recipe: recipe, ingredients: displayIngredients)
    }
}
