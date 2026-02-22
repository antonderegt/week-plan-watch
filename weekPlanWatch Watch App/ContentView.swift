//
//  ContentView.swift
//  weekPlanWatch Watch App
//
//  Created by Anton De Regt on 22/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var service = WeekPlanService()
    @State var checkedIDs: Set<String> = []

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView("Loading…")
            case .loaded(let recipe, let ingredients):
                NavigationStack {
                    TabView {
                        IngredientsView(recipe: recipe, ingredients: ingredients, checkedIDs: $checkedIDs)
                        StepsView(recipe: recipe)
                    }
                    .tabViewStyle(.page)
                }
            case .noRecipe(let msg), .error(let msg):
                Text(msg)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .task { await service.load() }
    }
}

#Preview {
    ContentView()
}
