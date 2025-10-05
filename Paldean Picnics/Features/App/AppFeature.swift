//
//  AppFeature.swift
//  Paldean Picnics
//
//  Root TCA feature coordinating all app features
//

import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var simulator = SimulatorFeature.State()
        var recipeBrowser = RecipeBrowserFeature.State()
        var mealBrowser = MealBrowserFeature.State()
        var calculator = CalculatorFeature.State()
        var selectedTab: Tab = .simulator

        enum Tab {
            case simulator
            case recipes
            case meals
            case calculator
        }
    }

    // MARK: - Action

    enum Action {
        case simulator(SimulatorFeature.Action)
        case recipeBrowser(RecipeBrowserFeature.Action)
        case mealBrowser(MealBrowserFeature.Action)
        case calculator(CalculatorFeature.Action)
        case selectTab(State.Tab)
        case loadRecipeInSimulator(SandwichRecipe)
        case loadMealInSimulator(Meal)
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Scope(state: \.simulator, action: \.simulator) {
            SimulatorFeature()
        }

        Scope(state: \.recipeBrowser, action: \.recipeBrowser) {
            RecipeBrowserFeature()
        }

        Scope(state: \.mealBrowser, action: \.mealBrowser) {
            MealBrowserFeature()
        }

        Scope(state: \.calculator, action: \.calculator) {
            CalculatorFeature()
        }

        Reduce { state, action in
            switch action {

            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            case .loadRecipeInSimulator(let recipe):
                // Switch to simulator tab and load recipe
                state.selectedTab = .simulator
                return .send(.simulator(.loadRecipe(recipe)))

            case .loadMealInSimulator(let meal):
                // Convert meal to recipe-like structure and load in simulator
                // For now, meals can't be loaded in simulator (they're pre-made)
                // TODO: Could add meal ingredients if data is available
                return .none

            case .simulator:
                return .none

            case .recipeBrowser(.selectRecipe(let recipe)):
                // When recipe is selected in browser, load it in simulator
                return .send(.loadRecipeInSimulator(recipe))

            case .recipeBrowser:
                return .none

            case .mealBrowser(.selectMeal):
                // Meals are pre-made, can't be simulated
                // TODO: Show meal detail view
                return .none

            case .mealBrowser:
                return .none

            case .calculator(.selectRecipe(let recipe)):
                // When recipe is selected from calculator, load it in simulator
                return .send(.loadRecipeInSimulator(recipe))

            case .calculator(.selectMeal):
                // Meals can't be simulated
                // TODO: Show meal detail view
                return .none

            case .calculator:
                return .none
            }
        }
    }
}
