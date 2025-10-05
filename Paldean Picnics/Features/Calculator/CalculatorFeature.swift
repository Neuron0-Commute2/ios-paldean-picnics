//
//  CalculatorFeature.swift
//  Paldean Picnics
//
//  TCA Feature for reverse-lookup calculator
//

import Foundation
import ComposableArchitecture

@Reducer
struct CalculatorFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var recipes: [SandwichRecipe] = []
        var meals: [Meal] = []
        var fillings: [Filling] = []
        var condiments: [Condiment] = []
        var searchTargets: [SearchTarget] = []
        var matchingRecipes: [SandwichRecipe] = []
        var matchingMeals: [Meal] = []
        var suggestedSandwiches: [CalculatedSandwich] = []
        var isLoading: Bool = false
        var isSearching: Bool = false
        var dataError: String? = nil

        // New target builder
        var selectedPower: MealPower = .sparkling
        var selectedType: PokemonType = .allTypes
        var selectedMinLevel: PowerLevel = .three

        var hasResults: Bool {
            !matchingRecipes.isEmpty || !matchingMeals.isEmpty || !suggestedSandwiches.isEmpty
        }

        var hasTargets: Bool {
            !searchTargets.isEmpty
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case dataLoaded(recipes: [SandwichRecipe], meals: [Meal], fillings: [Filling], condiments: [Condiment])
        case dataLoadFailed(Error)
        case addTarget
        case removeTarget(id: UUID)
        case executeSearch
        case searchResultsReceived(recipes: [SandwichRecipe], meals: [Meal], sandwiches: [CalculatedSandwich])
        case clearAll
        case selectRecipe(SandwichRecipe)
        case selectMeal(Meal)
    }

    // MARK: - Dependencies

    @Dependency(\.dataLoader) var dataLoader
    @Dependency(\.sandwichCalculator) var sandwichCalculator

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .onAppear:
                guard state.recipes.isEmpty && state.meals.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let recipes = try dataLoader.loadRecipes()
                        let meals = try dataLoader.loadMeals()
                        let fillings = try dataLoader.loadFillings()
                        let condiments = try dataLoader.loadCondiments()
                        await send(.dataLoaded(recipes: recipes, meals: meals, fillings: fillings, condiments: condiments))
                    } catch {
                        await send(.dataLoadFailed(error))
                    }
                }

            case let .dataLoaded(recipes, meals, fillings, condiments):
                state.isLoading = false
                state.recipes = recipes
                state.meals = meals
                state.fillings = fillings
                state.condiments = condiments
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                let errorMessage = "Failed to load data: \(error.localizedDescription)"
                state.dataError = errorMessage
                print("❌ [CalculatorFeature] \(errorMessage)")
                return .none

            case .addTarget:
                let newTarget = SearchTarget(
                    mealPower: state.selectedPower,
                    type: state.selectedType,
                    minLevel: state.selectedMinLevel
                )
                state.searchTargets.append(newTarget)
                return .none

            case let .removeTarget(id):
                state.searchTargets.removeAll { $0.id == id }
                return .none

            case .executeSearch:
                guard !state.searchTargets.isEmpty else { return .none }
                state.isSearching = true

                let recipes = state.recipes
                let meals = state.meals
                let fillings = state.fillings
                let condiments = state.condiments
                let targets = state.searchTargets
                let calculator = sandwichCalculator

                print("🔍 [Calculator] Starting search with \(targets.count) targets")
                print("🔍 [Calculator] Searching \(recipes.count) recipes, \(meals.count) meals, and ingredient combinations")
                targets.forEach { target in
                    print("🔍 [Calculator] Target: \(target.mealPower.fullName) \(target.type.displayName) Lv.\(target.minLevel.rawValue)+")
                }

                return .run { send in
                    // Search recipes
                    let matchingRecipes = recipes.filter { recipe in
                        targets.allSatisfy { target in
                            recipe.effects.contains { effect in
                                guard effect.mealPower == target.mealPower else { return false }
                                guard effect.level.rawValue >= target.minLevel.rawValue else { return false }
                                if target.type != .allTypes && effect.type != target.type {
                                    return false
                                }
                                return true
                            }
                        }
                    }

                    // Search meals
                    let matchingMeals = meals.filter { meal in
                        targets.allSatisfy { target in
                            meal.effects.contains { effect in
                                guard effect.mealPower == target.mealPower else { return false }
                                guard effect.level.rawValue >= target.minLevel.rawValue else { return false }
                                if target.type != .allTypes && effect.type != target.type {
                                    return false
                                }
                                return true
                            }
                        }
                    }

                    // Search ingredient combinations
                    let suggestedSandwiches = Self.searchIngredientCombinations(
                        fillings: fillings,
                        condiments: condiments,
                        targets: targets,
                        calculator: calculator,
                        recipes: recipes
                    )

                    print("✅ [Calculator] Found \(matchingRecipes.count) recipes, \(matchingMeals.count) meals, \(suggestedSandwiches.count) custom sandwiches")
                    await send(.searchResultsReceived(recipes: matchingRecipes, meals: matchingMeals, sandwiches: suggestedSandwiches))
                }

            case let .searchResultsReceived(recipes, meals, sandwiches):
                state.isSearching = false
                state.matchingRecipes = recipes
                state.matchingMeals = meals
                state.suggestedSandwiches = sandwiches
                return .none

            case .clearAll:
                state.searchTargets = []
                state.matchingRecipes = []
                state.matchingMeals = []
                state.suggestedSandwiches = []
                return .none

            case .selectRecipe, .selectMeal:
                // Navigation handled by parent feature
                return .none
            }
        }
    }

    // MARK: - Ingredient Combination Search

    /// Search through ingredient combinations using smart heuristics
    static func searchIngredientCombinations(
        fillings: [Filling],
        condiments: [Condiment],
        targets: [SearchTarget],
        calculator: SandwichCalculatorProtocol,
        recipes: [SandwichRecipe]
    ) -> [CalculatedSandwich] {

        var results: [CalculatedSandwich] = []
        let maxResults = 20

        // Determine Herba Mystica requirements
        let needsSparkling = targets.contains { $0.mealPower == .sparkling }
        let needsTitle = targets.contains { $0.mealPower == .title }
        let herbaCount = needsSparkling ? 2 : (needsTitle ? 1 : 0)

        let herbas = condiments.filter { $0.isHerbaMystica }
        let nonHerbas = condiments.filter { !$0.isHerbaMystica }

        print("🔬 [Calculator] Smart search: \(targets.count) targets, need \(herbaCount) Herba")

        // STEP 1: Score fillings by type relevance
        let targetTypes = Set(targets.map { $0.type }).filter { $0 != .allTypes }
        let scoredFillings = fillings.map { filling -> (filling: Filling, score: Int) in
            let typeScore = filling.types.reduce(0) { sum, typeValue in
                targetTypes.contains(typeValue.type) ? sum + typeValue.amount : sum
            }
            return (filling, typeScore)
        }.sorted { $0.score > $1.score }

        // STEP 2: Score condiments by power relevance
        let targetPowers = Set(targets.map { $0.mealPower })
        let scoredCondiments = nonHerbas.map { condiment -> (condiment: Condiment, score: Int) in
            let powerScore = condiment.powers.reduce(0) { sum, powerValue in
                targetPowers.contains(powerValue.type) ? sum + powerValue.amount : sum
            }
            return (condiment, powerScore)
        }.sorted { $0.score > $1.score }

        // STEP 3: Select Herba Mystica combinations
        let herbaSelections: [[Condiment]]
        if herbaCount > 0 && herbaCount <= herbas.count {
            herbaSelections = combinations(of: herbas, count: herbaCount).map { Array($0.prefix(herbaCount)) }
        } else if herbaCount > 0 {
            print("❌ [Calculator] Not enough Herba Mystica (\(herbas.count) available, need \(herbaCount))")
            return []
        } else {
            herbaSelections = [[]]
        }

        // STEP 4: Try top fillings (2-4 types, 1-3 pieces each)
        let topFillings = scoredFillings.prefix(12).map { $0.filling }

        for numFillings in 2...min(4, topFillings.count) {
            let fillingCombos = combinations(of: Array(topFillings), count: numFillings)

            for fillingSet in fillingCombos.prefix(50) {
                // Try different quantities
                for totalPieces in stride(from: numFillings, through: min(numFillings * 3, 12), by: 1) {
                    let piecesPerFilling = totalPieces / numFillings
                    let selectedFillings = fillingSet.map {
                        SelectedIngredient(ingredient: AnyIngredient(filling: $0), quantity: piecesPerFilling)
                    }

                    // STEP 5: Try condiment combinations
                    let topCondiments = scoredCondiments.prefix(10).map { $0.condiment }

                    for herbaSet in herbaSelections.prefix(5) {
                        // Try 2-3 regular condiments
                        for numRegular in 2...3 {
                            guard numRegular <= topCondiments.count else { continue }
                            let regularCombos = combinations(of: Array(topCondiments), count: numRegular)

                            for regularSet in regularCombos.prefix(10) {
                                let allCondiments = herbaSet + regularSet
                                let selectedCondiments = allCondiments.map {
                                    SelectedIngredient(ingredient: AnyIngredient(condiment: $0), quantity: 1)
                                }

                                // Calculate and test
                                let sandwich = calculator.calculateSandwich(
                                    fillings: selectedFillings,
                                    condiments: selectedCondiments,
                                    hasBread: true,
                                    numberOfPlayers: 1,
                                    recipes: recipes
                                )

                                // Check if matches ALL targets
                                let matches = targets.allSatisfy { target in
                                    sandwich.effects.contains { effect in
                                        effect.mealPower == target.mealPower &&
                                        effect.level.rawValue >= target.minLevel.rawValue &&
                                        (target.type == .allTypes || effect.type == target.type)
                                    }
                                }

                                if matches && !results.contains(where: { areSandwichesEqual($0, sandwich) }) {
                                    results.append(sandwich)
                                    print("✨ [Calculator] Match: \(sandwich.effects.map { "\($0.mealPower.alias) \($0.type.displayName) Lv.\($0.level.rawValue)" }.joined(separator: ", "))")

                                    if results.count >= maxResults {
                                        return sortSandwiches(results)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        print("✅ [Calculator] Found \(results.count) unique solutions")
        return sortSandwiches(results)
    }

    /// Sort sandwiches by ingredient count (fewer is better)
    private static func sortSandwiches(_ sandwiches: [CalculatedSandwich]) -> [CalculatedSandwich] {
        sandwiches.sorted { a, b in
            let aCount = a.fillings.count + a.condiments.count
            let bCount = b.fillings.count + b.condiments.count
            return aCount < bCount
        }
    }

    /// Check if two sandwiches have the same ingredients
    private static func areSandwichesEqual(_ a: CalculatedSandwich, _ b: CalculatedSandwich) -> Bool {
        let aIngredients = Set(a.fillings.map { $0.ingredient.id } + a.condiments.map { $0.ingredient.id })
        let bIngredients = Set(b.fillings.map { $0.ingredient.id } + b.condiments.map { $0.ingredient.id })
        return aIngredients == bIngredients
    }

    /// Generate all combinations of items of a given count
    private static func combinations<T>(of items: [T], count: Int) -> [[T]] {
        guard count > 0 else { return [[]] }
        guard count <= items.count else { return [] }

        if count == 1 {
            return items.map { [$0] }
        }

        var result: [[T]] = []
        for (index, item) in items.enumerated() {
            let remaining = Array(items.dropFirst(index + 1))
            let subCombos = combinations(of: remaining, count: count - 1)
            for subCombo in subCombos {
                result.append([item] + subCombo)
            }
        }
        return result
    }
}
