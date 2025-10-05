//
//  MealBrowserFeature.swift
//  Paldean Picnics
//
//  TCA Feature for meal browser
//

import Foundation
import ComposableArchitecture

@Reducer
struct MealBrowserFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var meals: [Meal] = []
        var searchQuery: String = ""
        var selectedTown: String = "All Towns"
        var selectedShop: String = "All Shops"
        var isLoading: Bool = false
        var dataError: String? = nil

        var availableTowns: [String] {
            let allTowns = Set(meals.flatMap { $0.towns })
            return ["All Towns"] + allTowns.sorted()
        }

        var availableShops: [String] {
            let allShops = Set(meals.map { $0.shop })
            return ["All Shops"] + allShops.sorted()
        }

        var filteredMeals: [Meal] {
            meals.filter { meal in
                // Search filter
                let matchesSearch = searchQuery.isEmpty ||
                    meal.name.localizedCaseInsensitiveContains(searchQuery) ||
                    meal.description.localizedCaseInsensitiveContains(searchQuery)

                // Town filter
                let matchesTown = selectedTown == "All Towns" ||
                    meal.towns.contains(selectedTown)

                // Shop filter
                let matchesShop = selectedShop == "All Shops" ||
                    meal.shop == selectedShop

                return matchesSearch && matchesTown && matchesShop
            }
        }

        var mealsGroupedByShop: [(shop: String, meals: [Meal])] {
            let grouped = Dictionary(grouping: filteredMeals, by: { $0.shop })
            return grouped
                .sorted { $0.key < $1.key }
                .map { (shop: $0.key, meals: $0.value.sorted { $0.costValue < $1.costValue }) }
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case dataLoaded([Meal])
        case dataLoadFailed(Error)
        case selectMeal(Meal)
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
                guard state.meals.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let meals = try dataLoader.loadMeals()
                        await send(.dataLoaded(meals))
                    } catch {
                        await send(.dataLoadFailed(error))
                    }
                }

            case let .dataLoaded(meals):
                state.isLoading = false
                state.meals = meals.sorted { meal1, meal2 in
                    // Sort by shop, then by cost
                    if meal1.shop != meal2.shop {
                        return meal1.shop < meal2.shop
                    }
                    return meal1.costValue < meal2.costValue
                }
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                let errorMessage = "Failed to load meals: \(error.localizedDescription)"
                state.dataError = errorMessage
                print("❌ [MealBrowserFeature] \(errorMessage)")
                if let dataError = error as? DataLoaderError {
                    print("   Details: \(dataError.errorDescription ?? "Unknown error")")
                }
                return .none

            case .selectMeal:
                // Navigation handled by parent feature
                return .none
            }
        }
    }
}
