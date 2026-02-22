import Foundation

nonisolated struct Ingredient: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let unit: String
}

nonisolated struct RecipeIngredient: Codable, Sendable {
    let ingredientId: String
    let quantity: Double
    let unit: String
}

nonisolated struct Recipe: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let ingredients: [RecipeIngredient]
    let steps: [String]
}

nonisolated struct MealBlock: Codable, Sendable {
    let id: String
    let recipeId: String
    let startDayIndex: Int
    let durationDays: Int
}

nonisolated struct Pattern: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let mealBlocks: [MealBlock]
}

nonisolated struct Settings: Codable, Sendable {
    let id: String
    let patternStartDate: String
    let patternOrder: [String]
}

nonisolated struct DisplayIngredient: Identifiable, Sendable {
    let id: String
    let name: String
    let quantity: Double
    let unit: String
}
