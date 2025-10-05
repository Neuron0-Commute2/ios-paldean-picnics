//
//  Ingredient.swift
//  Paldean Picnics
//
//  Models for sandwich ingredients (fillings and condiments)
//

import Foundation

// MARK: - Flavor Value

/// Represents a flavor contribution from an ingredient
struct FlavorValue: Codable, Hashable {
    let flavor: Flavor
    let amount: Int
}

// MARK: - Power Value

/// Represents a meal power contribution from an ingredient
struct PowerValue: Codable, Hashable {
    let type: MealPower
    let amount: Int // Can be negative
}

// MARK: - Type Value

/// Represents a Pokemon type affinity contribution from an ingredient
struct TypeValue: Codable, Hashable {
    let type: PokemonType
    let amount: Int
}

// MARK: - Ingredient Protocol

/// Common protocol for both fillings and condiments
protocol IngredientProtocol: Identifiable, Codable, Hashable {
    var id: String { get }
    var name: String { get }
    var tastes: [FlavorValue] { get }
    var powers: [PowerValue] { get }
    var types: [TypeValue] { get }
    var imageUrl: String { get }
    var ingredientType: IngredientType { get }
    var isHerbaMystica: Bool { get }
}

// MARK: - Filling

/// Represents a sandwich filling ingredient
struct Filling: IngredientProtocol {
    let id: String
    let name: String
    let tastes: [FlavorValue]
    let powers: [PowerValue]
    let types: [TypeValue]
    let imageUrl: String
    let pieces: Int // Default number of pieces
    let maxPiecesOnDish: Int // Maximum pieces allowed per sandwich

    var ingredientType: IngredientType { .filling }

    /// Whether this is a Herba Mystica ingredient (special rare item)
    var isHerbaMystica: Bool {
        name.lowercased().contains("herba mystica")
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case name, tastes, powers, types, imageUrl, pieces, maxPiecesOnDish, id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        tastes = try container.decode([FlavorValue].self, forKey: .tastes)
        powers = try container.decode([PowerValue].self, forKey: .powers)
        types = try container.decode([TypeValue].self, forKey: .types)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        pieces = try container.decode(Int.self, forKey: .pieces)

        // Handle both numeric and string IDs
        if let numericId = try? container.decode(Int.self, forKey: .id) {
            id = String(numericId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }

        maxPiecesOnDish = try container.decodeIfPresent(Int.self, forKey: .maxPiecesOnDish) ?? 6
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(tastes, forKey: .tastes)
        try container.encode(powers, forKey: .powers)
        try container.encode(types, forKey: .types)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(pieces, forKey: .pieces)
        try container.encode(id, forKey: .id)
        try container.encode(maxPiecesOnDish, forKey: .maxPiecesOnDish)
    }

    // Convenience initializer for testing/previews
    init(id: String, name: String, tastes: [FlavorValue], powers: [PowerValue],
         types: [TypeValue], imageUrl: String, pieces: Int, maxPiecesOnDish: Int) {
        self.id = id
        self.name = name
        self.tastes = tastes
        self.powers = powers
        self.types = types
        self.imageUrl = imageUrl
        self.pieces = pieces
        self.maxPiecesOnDish = maxPiecesOnDish
    }
}

// MARK: - Condiment

/// Represents a sandwich condiment ingredient
struct Condiment: IngredientProtocol {
    let id: String
    let name: String
    let tastes: [FlavorValue]
    let powers: [PowerValue]
    let types: [TypeValue]
    let imageUrl: String

    var ingredientType: IngredientType { .condiment }

    /// Whether this is a Herba Mystica ingredient (special rare item)
    var isHerbaMystica: Bool {
        name.lowercased().contains("herba mystica")
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case name, tastes, powers, types, imageUrl, cid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        tastes = try container.decode([FlavorValue].self, forKey: .tastes)
        powers = try container.decode([PowerValue].self, forKey: .powers)
        types = try container.decode([TypeValue].self, forKey: .types)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)

        // Handle both cid and id fields
        if let cid = try? container.decode(Int.self, forKey: .cid) {
            id = String(cid)
        } else {
            id = name // Fallback to name as ID
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(tastes, forKey: .tastes)
        try container.encode(powers, forKey: .powers)
        try container.encode(types, forKey: .types)
        try container.encode(imageUrl, forKey: .imageUrl)
        // Encode id as cid (numeric if possible)
        if let numericId = Int(id) {
            try container.encode(numericId, forKey: .cid)
        }
    }

    // Convenience initializer for testing/previews
    init(id: String, name: String, tastes: [FlavorValue], powers: [PowerValue],
         types: [TypeValue], imageUrl: String) {
        self.id = id
        self.name = name
        self.tastes = tastes
        self.powers = powers
        self.types = types
        self.imageUrl = imageUrl
    }
}

// MARK: - Selected Ingredient

/// Represents an ingredient selected by the user in the sandwich builder
/// Wraps either a Filling or Condiment with quantity information
struct SelectedIngredient: Identifiable, Hashable {
    let id: UUID
    let ingredient: AnyIngredient
    var quantity: Int // Number of pieces (for fillings) or applications (for condiments)

    init(ingredient: AnyIngredient, quantity: Int = 1) {
        self.id = UUID()
        self.ingredient = ingredient
        self.quantity = quantity
    }
}

// MARK: - Type-Erased Ingredient

/// Type-erased wrapper for IngredientProtocol to allow mixed collections
struct AnyIngredient: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let tastes: [FlavorValue]
    let powers: [PowerValue]
    let types: [TypeValue]
    let imageUrl: String
    let ingredientType: IngredientType
    let isHerbaMystica: Bool

    // Filling-specific properties (nil for condiments)
    let pieces: Int?
    let maxPiecesOnDish: Int?

    init(filling: Filling) {
        self.id = filling.id
        self.name = filling.name
        self.tastes = filling.tastes
        self.powers = filling.powers
        self.types = filling.types
        self.imageUrl = filling.imageUrl
        self.ingredientType = .filling
        self.isHerbaMystica = filling.isHerbaMystica
        self.pieces = filling.pieces
        self.maxPiecesOnDish = filling.maxPiecesOnDish
    }

    init(condiment: Condiment) {
        self.id = condiment.id
        self.name = condiment.name
        self.tastes = condiment.tastes
        self.powers = condiment.powers
        self.types = condiment.types
        self.imageUrl = condiment.imageUrl
        self.ingredientType = .condiment
        self.isHerbaMystica = condiment.isHerbaMystica
        self.pieces = nil
        self.maxPiecesOnDish = nil
    }
}
