//
//  Calculation.swift
//  Paldean Picnics
//
//  Models for sandwich calculation results and intermediate values
//

import Foundation

// MARK: - Calculated Sandwich

/// Represents the result of calculating a sandwich's effects from selected ingredients
struct CalculatedSandwich: Identifiable, Hashable {
    let id: UUID
    let fillings: [SelectedIngredient]
    let condiments: [SelectedIngredient]
    let effects: [CalculatedEffect]
    let matchedRecipe: SandwichRecipe? // If this matches a preset recipe
    let numberOfPlayers: Int // 1-4 for multiplayer mode
    let hasBread: Bool

    init(
        id: UUID = UUID(),
        fillings: [SelectedIngredient] = [],
        condiments: [SelectedIngredient] = [],
        effects: [CalculatedEffect] = [],
        matchedRecipe: SandwichRecipe? = nil,
        numberOfPlayers: Int = 1,
        hasBread: Bool = true
    ) {
        self.id = id
        self.fillings = fillings
        self.condiments = condiments
        self.effects = effects
        self.matchedRecipe = matchedRecipe
        self.numberOfPlayers = numberOfPlayers
        self.hasBread = hasBread
    }

    /// Total number of filling pieces
    var totalFillingPieces: Int {
        fillings.reduce(0) { $0 + $1.quantity }
    }

    /// Total number of condiment applications
    var totalCondiments: Int {
        condiments.count
    }

    /// Maximum allowed fillings based on number of players
    var maxFillings: Int {
        numberOfPlayers * 6
    }

    /// Maximum allowed condiments based on number of players
    var maxCondiments: Int {
        numberOfPlayers * 4
    }

    /// Whether the sandwich is valid (within limits)
    var isValid: Bool {
        totalFillingPieces <= maxFillings && totalCondiments <= maxCondiments
    }

    /// Whether this sandwich contains any Herba Mystica
    var hasHerbaMystica: Bool {
        condiments.contains { $0.ingredient.isHerbaMystica }
    }

    /// Count of Herba Mystica condiments
    var herbaMysticaCount: Int {
        condiments.filter { $0.ingredient.isHerbaMystica }.count
    }

    /// Primary effects (sorted by power level, descending)
    var primaryEffects: [CalculatedEffect] {
        Array(effects.sorted { $0.level > $1.level }.prefix(3))
    }
}

// MARK: - Calculated Effect

/// Represents a single calculated effect from a sandwich
struct CalculatedEffect: Identifiable, Hashable, Comparable {
    let id: UUID
    let mealPower: MealPower
    let type: PokemonType
    let level: PowerLevel
    let rawPowerValue: Int // The calculated power value before level conversion
    let rawTypeValue: Int  // The calculated type value before level conversion

    init(
        id: UUID = UUID(),
        mealPower: MealPower,
        type: PokemonType,
        level: PowerLevel,
        rawPowerValue: Int,
        rawTypeValue: Int
    ) {
        self.id = id
        self.mealPower = mealPower
        self.type = type
        self.level = level
        self.rawPowerValue = rawPowerValue
        self.rawTypeValue = rawTypeValue
    }

    /// Display name for UI
    var displayName: String {
        "\(mealPower.fullName): \(type.displayName) \(level.displayName)"
    }

    /// Sort effects by level (descending), then by power type
    static func < (lhs: CalculatedEffect, rhs: CalculatedEffect) -> Bool {
        if lhs.level != rhs.level {
            return lhs.level > rhs.level
        }
        return lhs.mealPower.rawValue < rhs.mealPower.rawValue
    }
}

// MARK: - Flavor Totals

/// Aggregated flavor values from all ingredients
struct FlavorTotals: Hashable {
    var sweet: Int = 0
    var salty: Int = 0
    var sour: Int = 0
    var bitter: Int = 0
    var spicy: Int = 0

    /// Get value for specific flavor
    subscript(flavor: Flavor) -> Int {
        get {
            switch flavor {
            case .sweet: return sweet
            case .salty: return salty
            case .sour: return sour
            case .bitter: return bitter
            case .spicy: return spicy
            }
        }
        set {
            switch flavor {
            case .sweet: sweet = newValue
            case .salty: salty = newValue
            case .sour: sour = newValue
            case .bitter: bitter = newValue
            case .spicy: spicy = newValue
            }
        }
    }

    /// Top two flavors (needed for power calculation algorithm)
    var topTwoFlavors: (Flavor, Flavor)? {
        let sorted = [
            (Flavor.sweet, sweet),
            (Flavor.salty, salty),
            (Flavor.sour, sour),
            (Flavor.bitter, bitter),
            (Flavor.spicy, spicy)
        ].sorted { $0.1 > $1.1 }

        guard sorted.count >= 2, sorted[0].1 > 0, sorted[1].1 > 0 else {
            return nil
        }

        return (sorted[0].0, sorted[1].0)
    }

    /// Total flavor value
    var total: Int {
        sweet + salty + sour + bitter + spicy
    }
}

// MARK: - Power Totals

/// Aggregated meal power values from all ingredients
struct PowerTotals: Hashable {
    var values: [MealPower: Int] = [:]

    subscript(power: MealPower) -> Int {
        get { values[power] ?? 0 }
        set { values[power] = newValue }
    }

    /// All powers with non-zero values
    var nonZeroPowers: [(MealPower, Int)] {
        values.filter { $0.value != 0 }.sorted { $0.value > $1.value }
    }
}

// MARK: - Type Totals

/// Aggregated Pokemon type affinity values from all ingredients
struct TypeTotals: Hashable {
    var values: [PokemonType: Int] = [:]

    subscript(type: PokemonType) -> Int {
        get { values[type] ?? 0 }
        set { values[type] = newValue }
    }

    /// Top types by value
    var topTypes: [(PokemonType, Int)] {
        values.filter { $0.value > 0 }.sorted { $0.value > $1.value }
    }
}

// MARK: - Optimization Result

/// Result from the linear programming optimization algorithm
struct OptimizationResult: Identifiable {
    let id: UUID
    let ingredients: [AnyIngredient]
    let quantities: [String: Int] // ingredient.id -> quantity
    let expectedEffects: [CalculatedEffect]
    let score: Double
    let isOptimal: Bool

    init(
        id: UUID = UUID(),
        ingredients: [AnyIngredient],
        quantities: [String: Int],
        expectedEffects: [CalculatedEffect],
        score: Double,
        isOptimal: Bool = true
    ) {
        self.id = id
        self.ingredients = ingredients
        self.quantities = quantities
        self.expectedEffects = expectedEffects
        self.score = score
        self.isOptimal = isOptimal
    }

    /// Convert to SelectedIngredient array for building a sandwich
    func toSelectedIngredients() -> (fillings: [SelectedIngredient], condiments: [SelectedIngredient]) {
        var fillings: [SelectedIngredient] = []
        var condiments: [SelectedIngredient] = []

        for ingredient in ingredients {
            if let quantity = quantities[ingredient.id], quantity > 0 {
                let selected = SelectedIngredient(ingredient: ingredient, quantity: quantity)
                switch ingredient.ingredientType {
                case .filling:
                    fillings.append(selected)
                case .condiment:
                    condiments.append(selected)
                }
            }
        }

        return (fillings, condiments)
    }
}
