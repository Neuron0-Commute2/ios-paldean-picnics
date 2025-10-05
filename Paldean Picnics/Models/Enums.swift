//
//  Enums.swift
//  Paldean Picnics
//
//  Core enumerations for sandwich system
//

import Foundation

// MARK: - Flavor

/// Represents the five flavor types in Pokemon Scarlet/Violet sandwiches
enum Flavor: String, Codable, CaseIterable, Identifiable {
    case sweet = "Sweet"
    case salty = "Salty"
    case sour = "Sour"
    case bitter = "Bitter"
    case spicy = "Hot" // Note: "Hot" in data, but "Spicy" conceptually

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .spicy: return "Spicy"
        default: return rawValue
        }
    }
}

// MARK: - Meal Power

/// Represents the ten meal power types available in sandwiches
enum MealPower: String, Codable, CaseIterable, Identifiable {
    case egg = "Egg"
    case catching = "Catch"
    case exp = "Exp"
    case item = "Item"
    case raid = "Raid"
    case sparkling = "Sparkling"
    case title = "Title"
    case humungo = "Humungo"
    case teensy = "Teensy"
    case encounter = "Encounter"

    var id: String { rawValue }

    /// Full display name for UI (e.g., "Egg Power")
    var fullName: String {
        switch self {
        case .catching: return "Catching Power"
        case .exp: return "Exp. Point Power"
        case .item: return "Item Drop Power"
        case .sparkling: return "Sparkling Power"
        case .title: return "Title Power"
        default: return "\(rawValue.capitalized) Power"
        }
    }

    /// Short alias for compact display
    var alias: String { rawValue }
}

// MARK: - Pokemon Type

/// Represents all 18 Pokemon types plus special "All Types" option
enum PokemonType: String, Codable, CaseIterable, Identifiable {
    case normal = "Normal"
    case fighting = "Fighting"
    case flying = "Flying"
    case poison = "Poison"
    case ground = "Ground"
    case rock = "Rock"
    case bug = "Bug"
    case ghost = "Ghost"
    case steel = "Steel"
    case fire = "Fire"
    case water = "Water"
    case grass = "Grass"
    case electric = "Electric"
    case psychic = "Psychic"
    case ice = "Ice"
    case dragon = "Dragon"
    case dark = "Dark"
    case fairy = "Fairy"
    case allTypes = "All Types"

    var id: String { rawValue }

    /// Display name (handles "All Types" case)
    var displayName: String { rawValue }
}

// MARK: - Currency

/// Represents the currency types for purchasing meals
enum Currency: String, Codable {
    case poke = "poke"
    case bp = "bp"

    /// Display symbol for UI
    var symbol: String {
        switch self {
        case .poke: return "₽" // Poké Dollar symbol
        case .bp: return "BP"
        }
    }

    /// Full name
    var displayName: String {
        switch self {
        case .poke: return "Poké Dollars"
        case .bp: return "Battle Points"
        }
    }
}

// MARK: - Ingredient Type

/// Distinguishes between filling and condiment ingredients
enum IngredientType: String, Codable {
    case filling = "filling"
    case condiment = "condiment"

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Power Level

/// Represents the level/tier of a meal power effect (1, 2, or 3)
enum PowerLevel: Int, Codable, Comparable, CaseIterable {
    case one = 1
    case two = 2
    case three = 3

    static func < (lhs: PowerLevel, rhs: PowerLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        "Lv. \(rawValue)"
    }
}
