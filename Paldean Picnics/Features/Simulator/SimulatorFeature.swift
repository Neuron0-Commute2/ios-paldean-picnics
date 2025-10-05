//
//  SimulatorFeature.swift
//  Paldean Picnics
//
//  TCA Feature for sandwich simulator
//

import Foundation
import ComposableArchitecture

@Reducer
struct SimulatorFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var availableFillings: [Filling] = []
        var availableCondiments: [Condiment] = []
        var selectedFillings: [SelectedIngredient] = []
        var selectedCondiments: [SelectedIngredient] = []
        var recipes: [SandwichRecipe] = []
        var calculatedSandwich: CalculatedSandwich?
        var numberOfPlayers: Int = 1
        var hasBread: Bool = true
        var isLoading: Bool = false
        var searchQuery: String = ""
        var dataError: String? = nil

        var filteredFillings: [Filling] {
            if searchQuery.isEmpty {
                return availableFillings
            }
            return availableFillings.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        var filteredCondiments: [Condiment] {
            if searchQuery.isEmpty {
                return availableCondiments
            }
            return availableCondiments.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        var totalFillingPieces: Int {
            selectedFillings.reduce(0) { $0 + $1.quantity }
        }

        var totalCondiments: Int {
            selectedCondiments.count
        }

        var maxFillings: Int {
            numberOfPlayers * 6
        }

        var maxCondiments: Int {
            numberOfPlayers * 4
        }

        var isValid: Bool {
            totalFillingPieces <= maxFillings && totalCondiments <= maxCondiments
        }

        var validationMessage: String? {
            if totalFillingPieces > maxFillings {
                return "Too many fillings! Max: \(maxFillings) (You have: \(totalFillingPieces))"
            }
            if totalCondiments > maxCondiments {
                return "Too many condiments! Max: \(maxCondiments) (You have: \(totalCondiments))"
            }
            return nil
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case dataLoaded(fillings: [Filling], condiments: [Condiment], recipes: [SandwichRecipe])
        case dataLoadFailed(Error)
        case addFilling(Filling)
        case addCondiment(Condiment)
        case removeIngredient(id: UUID)
        case updateQuantity(id: UUID, quantity: Int)
        case clearSandwich
        case recalculate
        case loadRecipe(SandwichRecipe)
    }

    // MARK: - Dependencies

    @Dependency(\.dataLoader) var dataLoader
    @Dependency(\.sandwichCalculator) var calculator

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                // Recalculate when binding values change
                return .send(.recalculate)

            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let fillings = try dataLoader.loadFillings()
                        let condiments = try dataLoader.loadCondiments()
                        let recipes = try dataLoader.loadRecipes()
                        await send(.dataLoaded(
                            fillings: fillings,
                            condiments: condiments,
                            recipes: recipes
                        ))
                    } catch {
                        await send(.dataLoadFailed(error))
                    }
                }

            case let .dataLoaded(fillings, condiments, recipes):
                state.isLoading = false
                state.availableFillings = fillings.sorted { $0.name < $1.name }
                state.availableCondiments = condiments.sorted { $0.name < $1.name }
                state.recipes = recipes
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                let errorMessage = "Failed to load data: \(error.localizedDescription)"
                state.dataError = errorMessage
                print("❌ [SimulatorFeature] \(errorMessage)")
                if let dataError = error as? DataLoaderError {
                    print("   Details: \(dataError.errorDescription ?? "Unknown error")")
                }
                return .none

            case let .addFilling(filling):
                let anyIngredient = AnyIngredient(filling: filling)
                state.selectedFillings.append(SelectedIngredient(
                    ingredient: anyIngredient,
                    quantity: filling.pieces
                ))
                return .send(.recalculate)

            case let .addCondiment(condiment):
                let anyIngredient = AnyIngredient(condiment: condiment)
                state.selectedCondiments.append(SelectedIngredient(
                    ingredient: anyIngredient,
                    quantity: 1
                ))
                return .send(.recalculate)

            case let .removeIngredient(id):
                state.selectedFillings.removeAll { $0.id == id }
                state.selectedCondiments.removeAll { $0.id == id }
                return .send(.recalculate)

            case let .updateQuantity(id, quantity):
                if let index = state.selectedFillings.firstIndex(where: { $0.id == id }) {
                    if quantity > 0 {
                        state.selectedFillings[index].quantity = quantity
                    } else {
                        state.selectedFillings.remove(at: index)
                    }
                }
                return .send(.recalculate)

            case .clearSandwich:
                state.selectedFillings = []
                state.selectedCondiments = []
                state.calculatedSandwich = nil
                state.searchQuery = ""
                return .none

            case .recalculate:
                guard !state.selectedFillings.isEmpty || !state.selectedCondiments.isEmpty else {
                    state.calculatedSandwich = nil
                    return .none
                }

                let calculated = calculator.calculateSandwich(
                    fillings: state.selectedFillings,
                    condiments: state.selectedCondiments,
                    hasBread: state.hasBread,
                    numberOfPlayers: state.numberOfPlayers,
                    recipes: state.recipes
                )
                state.calculatedSandwich = calculated
                return .none

            case let .loadRecipe(recipe):
                // Clear current sandwich
                state.selectedFillings = []
                state.selectedCondiments = []

                // Load recipe fillings
                for fillingName in recipe.fillings {
                    if let filling = state.availableFillings.first(where: { $0.name == fillingName }) {
                        let anyIngredient = AnyIngredient(filling: filling)
                        state.selectedFillings.append(SelectedIngredient(
                            ingredient: anyIngredient,
                            quantity: filling.pieces
                        ))
                    }
                }

                // Load recipe condiments
                for condimentName in recipe.condiments {
                    if let condiment = state.availableCondiments.first(where: { $0.name == condimentName }) {
                        let anyIngredient = AnyIngredient(condiment: condiment)
                        state.selectedCondiments.append(SelectedIngredient(
                            ingredient: anyIngredient,
                            quantity: 1
                        ))
                    }
                }

                state.hasBread = true // Recipes always use bread
                return .send(.recalculate)
            }
        }
    }
}
