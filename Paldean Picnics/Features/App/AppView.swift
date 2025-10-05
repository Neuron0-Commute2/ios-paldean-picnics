//
//  AppView.swift
//  Paldean Picnics
//
//  Root view with tab navigation
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            SimulatorView(store: store.scope(state: \.simulator, action: \.simulator))
                .tabItem {
                    Label("Simulator", systemImage: "fork.knife")
                }
                .tag(AppFeature.State.Tab.simulator)

            CalculatorView(
                store: store.scope(state: \.calculator, action: \.calculator),
                onSelectRecipe: { recipe in
                    store.send(.loadRecipeInSimulator(recipe))
                },
                onSelectMeal: { meal in
                    store.send(.loadMealInSimulator(meal))
                }
            )
            .tabItem {
                Label("Calculator", systemImage: "sparkles.square.filled.on.square")
            }
            .tag(AppFeature.State.Tab.calculator)

            RecipeBrowserView(
                store: store.scope(state: \.recipeBrowser, action: \.recipeBrowser),
                onSelectRecipe: { recipe in
                    store.send(.loadRecipeInSimulator(recipe))
                }
            )
            .tabItem {
                Label("Recipes", systemImage: "book.fill")
            }
            .tag(AppFeature.State.Tab.recipes)

            MealBrowserView(
                store: store.scope(state: \.mealBrowser, action: \.mealBrowser),
                onSelectMeal: { meal in
                    store.send(.loadMealInSimulator(meal))
                }
            )
            .tabItem {
                Label("Meals", systemImage: "fork.knife.circle")
            }
            .tag(AppFeature.State.Tab.meals)
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) {
        AppFeature()
    })
}
