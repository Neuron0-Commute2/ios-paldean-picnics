//
//  SandwichCalculator.swift
//  Paldean Picnics
//
//  Service for calculating sandwich effects from ingredients
//  Ported from pokemon-sandwich-simulator/src/helper/helper.js
//

import Foundation
import ComposableArchitecture

// MARK: - Protocol

/// Protocol for calculating sandwich effects
protocol SandwichCalculatorProtocol {
    /// Calculate sandwich effects from selected ingredients
    func calculateSandwich(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        hasBread: Bool,
        numberOfPlayers: Int,
        recipes: [SandwichRecipe]
    ) -> CalculatedSandwich
}

// MARK: - Live Implementation

/// Production implementation of sandwich calculation algorithm
struct LiveSandwichCalculator: SandwichCalculatorProtocol {

    func calculateSandwich(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        hasBread: Bool,
        numberOfPlayers: Int,
        recipes: [SandwichRecipe]
    ) -> CalculatedSandwich {

        // Check if this matches a preset recipe
        let matchedRecipe = matchPresetRecipe(
            fillings: fillings,
            condiments: condiments,
            hasBread: hasBread,
            recipes: recipes
        )

        // Calculate flavors and deliciousness
        let (flavorTotals, deliciousness) = calculateFlavorTotals(
            fillings: fillings,
            condiments: condiments,
            hasBread: hasBread,
            numberOfPlayers: numberOfPlayers
        )

        // Calculate meal powers
        let powerTotals = calculatePowerTotals(
            fillings: fillings,
            condiments: condiments,
            flavorTotals: flavorTotals
        )

        // Calculate Pokemon types
        let typeTotals = calculateTypeTotals(
            fillings: fillings,
            condiments: condiments,
            deliciousness: deliciousness
        )

        // Determine final effects
        let effects = determineEffects(
            powerTotals: powerTotals,
            typeTotals: typeTotals
        )

        return CalculatedSandwich(
            fillings: fillings,
            condiments: condiments,
            effects: effects,
            matchedRecipe: matchedRecipe,
            numberOfPlayers: numberOfPlayers,
            hasBread: hasBread
        )
    }

    // MARK: - Flavor Calculation (getTastesAndDeliciousness)

    /// Calculate flavor totals and deliciousness level
    /// - Returns: (FlavorTotals, deliciousness: 0-3)
    private func calculateFlavorTotals(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        hasBread: Bool,
        numberOfPlayers: Int
    ) -> (FlavorTotals, Int) {

        var flavorTotals = FlavorTotals()

        // Map filling name to total pieces
        var fillingPieceMap: [String: Int] = [:]

        // Aggregate flavor values from fillings
        for filling in fillings {
            let name = filling.ingredient.name
            fillingPieceMap[name, default: 0] += filling.quantity

            for flavorValue in filling.ingredient.tastes {
                flavorTotals[flavorValue.flavor] += flavorValue.amount * filling.quantity
            }
        }

        // Aggregate flavor values from condiments
        for condiment in condiments {
            for flavorValue in condiment.ingredient.tastes {
                flavorTotals[flavorValue.flavor] += flavorValue.amount
            }
        }

        // Calculate deliciousness (0-3)
        var deliciousness = 1 // default

        // Check if same ingredient pieces >= limit (0 stars)
        let ingredientLimit = CalculationConstants.ingredientLimit(for: numberOfPlayers)
        for pieces in fillingPieceMap.values {
            if pieces >= ingredientLimit {
                deliciousness = 0
                return (flavorTotals, deliciousness)
            }
        }

        // Check if all flavors >= 100 (3 stars)
        let isVeryGood = Flavor.allCases.allSatisfy { flavorTotals[$0] >= 100 }
        if isVeryGood {
            deliciousness = 3
            return (flavorTotals, deliciousness)
        }

        // Check drop count logic (2 stars)
        let totalPiecesOnSandwich = fillingPieceMap.values.reduce(0, +) + (hasBread ? 1 : 0)

        // Total pieces if nothing dropped
        var totalPiecesMax = 0
        for filling in fillings {
            if let pieces = filling.ingredient.pieces {
                totalPiecesMax += pieces
            }
        }

        let dropNum = totalPiecesMax - totalPiecesOnSandwich
        let fillingsAmount = Set(fillings.map { $0.ingredient.id }).count

        if dropNum <= fillingsAmount {
            deliciousness = 2
        }

        return (flavorTotals, deliciousness)
    }

    // MARK: - Power Calculation (getSkills)

    /// Calculate meal power totals with flavor combination bonuses
    private func calculatePowerTotals(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        flavorTotals: FlavorTotals
    ) -> PowerTotals {

        var powerTotals = PowerTotals()

        // Add up power values from fillings
        for filling in fillings {
            for powerValue in filling.ingredient.powers {
                powerTotals[powerValue.type] += powerValue.amount * filling.quantity
            }
        }

        // Add up power values from condiments
        for condiment in condiments {
            for powerValue in condiment.ingredient.powers {
                powerTotals[powerValue.type] += powerValue.amount
            }
        }

        // Add Herba Mystica bonuses
        let herbaCount = getHerbaCount(condiments: condiments)
        if herbaCount >= 1 {
            powerTotals[.title] += 10000
        }
        if herbaCount >= 2 {
            powerTotals[.sparkling] += 20000
        }

        // Apply flavor combination bonuses using PRIME NUMBER MATCHING
        let topFlavors = getTopFlavors(flavorTotals: flavorTotals)

        for rule in CalculationConstants.tastePowerRules {
            var addPowMag = 1
            var tastePowMag = 1
            var isMatch = false

            // Calculate magnitudes using prime multiplication
            for (index, taste) in rule.tastes.enumerated() {
                addPowMag *= CalculationConstants.indexToPrime(taste)
                if index < topFlavors.count {
                    tastePowMag *= CalculationConstants.indexToPrime(topFlavors[index])
                }
            }

            if addPowMag == tastePowMag {
                isMatch = true
            }

            if isMatch {
                let skillIndex = rule.skillType - 1 // Convert to 0-indexed
                if skillIndex >= 0 && skillIndex < CalculationConstants.mealPowers.count {
                    let mealPower = CalculationConstants.mealPowers[skillIndex]
                    powerTotals[mealPower] += rule.power
                }
                break // Only apply first matching rule
            }
        }

        return powerTotals
    }

    // MARK: - Type Calculation (getTypes)

    /// Calculate Pokemon type totals with deliciousness modifiers
    private func calculateTypeTotals(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        deliciousness: Int
    ) -> TypeTotals {

        var typeTotals = TypeTotals()

        // Add up type values from fillings
        for filling in fillings {
            for typeValue in filling.ingredient.types {
                typeTotals[typeValue.type] += typeValue.amount * filling.quantity
            }
        }

        // Add up type values from condiments
        for condiment in condiments {
            for typeValue in condiment.ingredient.types {
                typeTotals[typeValue.type] += typeValue.amount
            }
        }

        // Add deliciousness modifiers to ALL types
        let dPoints = CalculationConstants.deliciousnessModifiers[deliciousness]
        for type in PokemonType.allCases where type != .allTypes {
            typeTotals[type] += dPoints
        }

        return typeTotals
    }

    // MARK: - Effects Determination (getEffects)

    /// Combine powers and types to create final effects
    private func determineEffects(
        powerTotals: PowerTotals,
        typeTotals: TypeTotals
    ) -> [CalculatedEffect] {

        var effects: [CalculatedEffect] = []

        // Get top 3 powers and top 3 types
        let topPowers = powerTotals.nonZeroPowers.prefix(3)
        let topTypes = typeTotals.topTypes.prefix(3)

        var typeIndex = 0

        for (power, powerValue) in topPowers {
            guard powerValue > 0 else { break }
            guard typeIndex < topTypes.count else { break }

            let (type, typeValue) = topTypes[typeIndex]
            let level = getFoodSkillLevel(power: typeValue)

            guard level.rawValue > 0 else { break }

            // Egg power has no type
            let finalType: PokemonType = (power == .egg) ? .allTypes : type

            effects.append(CalculatedEffect(
                mealPower: power,
                type: finalType,
                level: level,
                rawPowerValue: powerValue,
                rawTypeValue: typeValue
            ))

            typeIndex += 1

            if effects.count >= 3 {
                break
            }
        }

        return effects
    }

    // MARK: - Recipe Matching (checkPresetSandwich)

    /// Check if ingredients match a preset recipe
    private func matchPresetRecipe(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        hasBread: Bool,
        recipes: [SandwichRecipe]
    ) -> SandwichRecipe? {

        // Preset recipes always use bread
        guard hasBread else { return nil }

        // Sort ingredients by name for comparison
        let sortedFillings = fillings.sorted { $0.ingredient.name < $1.ingredient.name }
        let sortedCondiments = condiments.sorted { $0.ingredient.name < $1.ingredient.name }

        let ingredientNames = sortedFillings.map { $0.ingredient.name } + sortedCondiments.map { $0.ingredient.name }

        for recipe in recipes {
            let recipeIngredients = recipe.fillings + recipe.condiments

            // Check if ingredient names match
            guard areEqual(ingredientNames, recipeIngredients) else { continue }

            // Check if pieces match (fillings only)
            let fillingPieces = sortedFillings.map { $0.ingredient.pieces ?? 0 }
            let recipePieces = recipe.fillings.compactMap { name -> Int? in
                fillings.first { $0.ingredient.name == name }?.ingredient.pieces
            }

            guard areEqual(fillingPieces, recipePieces) else { continue }

            return recipe
        }

        return nil
    }

    // MARK: - Helper Functions

    /// Get Herba Mystica count from condiments
    private func getHerbaCount(condiments: [SelectedIngredient]) -> Int {
        condiments.filter { $0.ingredient.isHerbaMystica }.count
    }

    /// Convert power value to level (1, 2, or 3)
    private func getFoodSkillLevel(power: Int) -> PowerLevel {
        let thresholds = CalculationConstants.powerLevelThresholds
        if power >= thresholds[2] { return .three }
        if power >= thresholds[1] { return .two }
        if power >= thresholds[0] { return .one }
        return .one // Should not happen if power > 0
    }

    /// Get top flavors sorted by value (returns flavor type indices)
    private func getTopFlavors(flavorTotals: FlavorTotals) -> [Int] {
        let sorted = Flavor.allCases
            .map { (flavor: $0, value: flavorTotals[$0]) }
            .sorted { $0.value > $1.value }

        return sorted.map { CalculationConstants.flavorTypeMap[$0.flavor] ?? 0 }
    }

    /// Check if two arrays contain the same elements (order-independent)
    private func areEqual<T: Equatable>(_ array1: [T], _ array2: [T]) -> Bool {
        guard array1.count == array2.count else { return false }

        let diff = array1.filter { element in
            !array2.contains(element) ||
            array2.filter { $0 == element }.count != array1.filter { $0 == element }.count
        }

        return diff.isEmpty
    }
}

// MARK: - Unimplemented (for testing)

/// Unimplemented version that throws fatal errors - used as default testValue
struct UnimplementedSandwichCalculator: SandwichCalculatorProtocol {
    func calculateSandwich(
        fillings: [SelectedIngredient],
        condiments: [SelectedIngredient],
        hasBread: Bool,
        numberOfPlayers: Int,
        recipes: [SandwichRecipe]
    ) -> CalculatedSandwich {
        XCTFail("SandwichCalculator.calculateSandwich is unimplemented")
        return CalculatedSandwich()
    }
}

// MARK: - TCA Dependency

private enum SandwichCalculatorKey: DependencyKey {
    static let liveValue: any SandwichCalculatorProtocol = LiveSandwichCalculator()
    static let testValue: any SandwichCalculatorProtocol = UnimplementedSandwichCalculator()
    static let previewValue: any SandwichCalculatorProtocol = LiveSandwichCalculator()
}

extension DependencyValues {
    var sandwichCalculator: SandwichCalculatorProtocol {
        get { self[SandwichCalculatorKey.self] }
        set { self[SandwichCalculatorKey.self] = newValue }
    }
}
