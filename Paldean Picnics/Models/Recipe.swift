//
//  Recipe.swift
//  Paldean Picnics
//
//  Models for sandwich recipes and meals
//

import Foundation

// MARK: - Sandwich Effect

/// Represents a single effect/power granted by a sandwich or meal
struct SandwichEffect: Codable, Hashable, Identifiable {
    let name: String // Full name like "Egg Power", "Catching Power", etc.
    let type: PokemonType // Pokemon type this effect applies to (or .allTypes)
    let level: PowerLevel // Level 1, 2, or 3

    var id: String {
        "\(name)-\(type.rawValue)-\(level.rawValue)"
    }

    /// The meal power type extracted from the name
    var mealPower: MealPower? {
        // Map full names to MealPower enum
        if name.contains("Egg") { return .egg }
        if name.contains("Catch") { return .catching }
        if name.contains("Exp") { return .exp }
        if name.contains("Item") { return .item }
        if name.contains("Raid") { return .raid }
        if name.contains("Sparkling") { return .sparkling }
        if name.contains("Title") { return .title }
        if name.contains("Humungo") { return .humungo }
        if name.contains("Teensy") { return .teensy }
        if name.contains("Encounter") { return .encounter }
        return nil
    }

    // Custom coding to handle string level values
    enum CodingKeys: String, CodingKey {
        case name, type, level
    }

    init(name: String, type: PokemonType, level: PowerLevel) {
        self.name = name
        self.type = type
        self.level = level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        // Handle type - empty string means "All Types"
        let typeString = try container.decode(String.self, forKey: .type)
        if typeString.isEmpty {
            type = .allTypes
        } else {
            type = try container.decode(PokemonType.self, forKey: .type)
        }

        // Handle level as either string or int
        if let levelInt = try? container.decode(Int.self, forKey: .level) {
            level = PowerLevel(rawValue: levelInt) ?? .one
        } else if let levelString = try? container.decode(String.self, forKey: .level),
                  let levelInt = Int(levelString) {
            level = PowerLevel(rawValue: levelInt) ?? .one
        } else {
            level = .one
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)

        // Encode "All Types" as empty string to match original format
        if type == .allTypes {
            try container.encode("", forKey: .type)
        } else {
            try container.encode(type, forKey: .type)
        }

        try container.encode(level.rawValue, forKey: .level)
    }
}

// MARK: - Raw Effect Values

/// Represents the raw numerical values used to calculate sandwich effects
/// These are the intermediate calculation values from the game's algorithm
struct RawEffectValues: Codable, Hashable {
    let powers: [String: Int] // e.g., ["Catching Power": 80, "Raid Power": 85]
    let types: [String: Int]   // e.g., ["Ground": 90, "Bug": 80]

    init(powers: [String: Int] = [:], types: [String: Int] = [:]) {
        self.powers = powers
        self.types = types
    }
}

// MARK: - Sandwich Recipe

/// Represents a preset sandwich recipe from the game
struct SandwichRecipe: Codable, Identifiable, Hashable {
    let number: String // Recipe number (e.g., "1", "17", "-1" for hidden)
    let name: String
    let description: String
    let fillings: [String] // Array of ingredient names
    let condiments: [String] // Array of ingredient names
    let effects: [SandwichEffect]
    let imageUrl: String
    let location: String // Where to unlock this recipe (e.g., "Start", "Unavailable")
    let rawEffectValues: RawEffectValues

    var id: String { number }

    /// Whether this is a hidden/unavailable recipe
    var isHidden: Bool {
        location == "Unavailable" || number.hasPrefix("-")
    }

    /// Numeric recipe number (nil for hidden recipes with negative numbers)
    var recipeNumber: Int? {
        Int(number)
    }

    /// Total ingredient count
    var totalIngredients: Int {
        fillings.count + condiments.count
    }
}

// MARK: - Meal

/// Represents a pre-made meal available at restaurants
struct Meal: Codable, Identifiable, Hashable {
    let number: String // Meal number identifier
    let name: String
    let description: String
    let cost: String // Stored as string, convert to Int for calculations
    let effects: [SandwichEffect]
    let shop: String // Restaurant name
    let towns: [String] // List of towns where this meal is available
    let imageUrl: String

    var id: String { number }

    /// Cost as integer
    var costValue: Int {
        Int(cost) ?? 0
    }

    /// Currency type (always Poke for meals)
    var currency: Currency {
        .poke
    }

    /// Whether this meal is available in a specific town
    func isAvailable(in town: String) -> Bool {
        towns.contains(town)
    }

    /// Primary effect (usually the first one listed)
    var primaryEffect: SandwichEffect? {
        effects.first
    }
}

// MARK: - Search Target

/// Represents a target effect that the user is searching for in the calculator
struct SearchTarget: Identifiable, Hashable {
    let id: UUID
    let mealPower: MealPower
    let type: PokemonType
    let minLevel: PowerLevel

    init(mealPower: MealPower, type: PokemonType, minLevel: PowerLevel = .one) {
        self.id = UUID()
        self.mealPower = mealPower
        self.type = type
        self.minLevel = minLevel
    }

    /// Display string for UI
    var displayName: String {
        "\(mealPower.fullName) - \(type.displayName) Lv.\(minLevel.rawValue)+"
    }
}
