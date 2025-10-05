//
//  CalculationConstants.swift
//  Paldean Picnics
//
//  Constants and lookup tables for sandwich calculation algorithm
//  Ported from pokemon-sandwich-simulator/src/helper/
//

import Foundation

enum CalculationConstants {

    // MARK: - Flavor Type Map (taste-map.json)

    /// Maps flavor names to their numeric type for calculation purposes
    /// Hot=0, Sweet=1, Salty=2, Sour=3, Bitter=4
    static let flavorTypeMap: [Flavor: Int] = [
        .spicy: 0,  // "Hot" in original data
        .sweet: 1,
        .salty: 2,
        .sour: 3,
        .bitter: 4
    ]

    /// Maps numeric types to prime numbers for flavor matching algorithm
    /// Used in the prime number multiplication trick
    static func indexToPrime(_ num: Int) -> Int {
        [2, 3, 5, 7, 11][num] ?? 1
    }

    // MARK: - Taste Power Rules (taste-powers.json)

    /// Rules for which flavor combinations grant which meal powers
    /// Uses prime number matching: multiply flavor type primes and match
    struct TastePowerRule {
        let tastes: [Int]        // Flavor type indices
        let skillType: Int       // MealPower index (1-10)
        let power: Int           // Power value added
    }

    static let tastePowerRules: [TastePowerRule] = [
        TastePowerRule(tastes: [1, 0], skillType: 5, power: 100),  // Sweet+Hot → Raid
        TastePowerRule(tastes: [1, 3], skillType: 2, power: 100),  // Sweet+Sour → Catching
        TastePowerRule(tastes: [4, 2], skillType: 3, power: 100),  // Bitter+Salty → Exp
        TastePowerRule(tastes: [1], skillType: 1, power: 100),     // Sweet → Egg
        TastePowerRule(tastes: [0], skillType: 8, power: 100),     // Hot → Humungo
        TastePowerRule(tastes: [2], skillType: 10, power: 100),    // Salty → Encounter
        TastePowerRule(tastes: [3], skillType: 9, power: 100),     // Sour → Teensy
        TastePowerRule(tastes: [4], skillType: 4, power: 100)      // Bitter → Item
    ]

    // MARK: - Skill Level Point Table (skill-level-point-table.json)

    /// Thresholds for power levels
    /// [Lv 1 threshold, Lv 2 threshold, Lv 3 threshold]
    static let powerLevelThresholds: [Int] = [1, 200, 400]

    // MARK: - Deliciousness Pokemon Type Points (deliciousness-poketype-points.json)

    /// Modifiers applied to ALL Pokemon types based on deliciousness level
    /// Index corresponds to deliciousness (0-5)
    /// Deliciousness range: 0 (bad) to 3 (very good), but array has 6 elements
    static let deliciousnessModifiers: [Int] = [-500, 0, 20, 100, 0, 0]

    // MARK: - MealPower Array (for indexing)

    /// All meal powers in order (1-indexed in original algorithm)
    static let mealPowers: [MealPower] = [
        .egg,       // 1
        .catching,  // 2
        .exp,       // 3
        .item,      // 4
        .raid,      // 5
        .sparkling, // 6
        .title,     // 7
        .humungo,   // 8
        .teensy,    // 9
        .encounter  // 10
    ]

    // MARK: - Ingredient Limits by Player Count

    static func ingredientLimit(for numberOfPlayers: Int) -> Int {
        switch numberOfPlayers {
        case 1, 2: return 13
        case 3: return 19
        case 4: return 25
        default: return 13
        }
    }

    static func maxFillings(for numberOfPlayers: Int) -> Int {
        numberOfPlayers * 6
    }

    static func maxCondiments(for numberOfPlayers: Int) -> Int {
        numberOfPlayers * 4
    }
}
