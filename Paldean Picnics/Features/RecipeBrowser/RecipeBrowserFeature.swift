//
//  RecipeBrowserFeature.swift
//  Paldean Picnics
//
//  TCA Feature for recipe browser
//

import Foundation
import ComposableArchitecture

@Reducer
struct RecipeBrowserFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var recipes: [SandwichRecipe] = []
        var searchQuery: String = ""
        var isLoading: Bool = false
        var dataError: String? = nil

        var filteredRecipes: [SandwichRecipe] {
            if searchQuery.isEmpty {
                return recipes.filter { !$0.isHidden } // Hide unavailable recipes by default
            }
            return recipes.filter { recipe in
                !recipe.isHidden &&
                (recipe.name.localizedCaseInsensitiveContains(searchQuery) ||
                 recipe.description.localizedCaseInsensitiveContains(searchQuery))
            }
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case dataLoaded([SandwichRecipe])
        case dataLoadFailed(Error)
        case selectRecipe(SandwichRecipe)
    }

    // MARK: - Dependencies

    @Dependency(\.dataLoader) var dataLoader

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .onAppear:
                guard state.recipes.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let recipes = try dataLoader.loadRecipes()
                        await send(.dataLoaded(recipes))
                    } catch {
                        await send(.dataLoadFailed(error))
                    }
                }

            case let .dataLoaded(recipes):
                state.isLoading = false
                state.recipes = recipes.sorted { recipe1, recipe2 in
                    // Sort by number (convert to int, handle hidden recipes)
                    if let num1 = Int(recipe1.number), let num2 = Int(recipe2.number) {
                        return num1 < num2
                    }
                    return recipe1.number < recipe2.number
                }
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                let errorMessage = "Failed to load recipes: \(error.localizedDescription)"
                state.dataError = errorMessage
                print("❌ [RecipeBrowserFeature] \(errorMessage)")
                if let dataError = error as? DataLoaderError {
                    print("   Details: \(dataError.errorDescription ?? "Unknown error")")
                }
                return .none

            case .selectRecipe:
                // Navigation handled by parent feature
                return .none
            }
        }
    }
}
