import SwiftUI

struct IngredientsView: View {
    let recipe: Recipe
    let ingredients: [DisplayIngredient]
    @Binding var checkedIDs: Set<String>

    var body: some View {
        List(ingredients) { ingredient in
            Button {
                if checkedIDs.contains(ingredient.id) {
                    checkedIDs.remove(ingredient.id)
                } else {
                    checkedIDs.insert(ingredient.id)
                }
            } label: {
                HStack {
                    Image(systemName: checkedIDs.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checkedIDs.contains(ingredient.id) ? Color.accentColor : Color.secondary)
                    Text(ingredient.name)
                    Spacer()
                    Text("\(ingredient.quantity.formatted()) \(ingredient.unit)")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
