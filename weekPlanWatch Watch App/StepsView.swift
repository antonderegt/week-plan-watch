import SwiftUI

struct StepsView: View {
    let recipe: Recipe

    var body: some View {
        List(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top, spacing: 8) {
                Text("\(index + 1).")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .frame(minWidth: 20, alignment: .trailing)
                Text(step)
                    .font(.footnote)
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
