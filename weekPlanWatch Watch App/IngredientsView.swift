import SwiftUI

struct IngredientsView: View {
    let recipe: Recipe
    let ingredients: [DisplayIngredient]
    @Binding var checkedIDs: Set<String>
    var onRefresh: () -> Void

    var body: some View {
        List {
            ForEach(ingredients) { ingredient in
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
            Button {
                onRefresh()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
