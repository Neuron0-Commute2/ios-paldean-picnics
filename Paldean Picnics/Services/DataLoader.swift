//
//  DataLoader.swift
//  Paldean Picnics
//
//  Service for loading game data from JSON files
//

import Foundation
import ComposableArchitecture

// MARK: - Protocol

/// Protocol for loading sandwich data from JSON files
protocol DataLoaderProtocol {
    /// Load all filling ingredients
    func loadFillings() throws -> [Filling]

    /// Load all condiment ingredients
    func loadCondiments() throws -> [Condiment]

    /// Load all preset sandwich recipes
    func loadRecipes() throws -> [SandwichRecipe]

    /// Load all restaurant meals
    func loadMeals() throws -> [Meal]
}

// MARK: - Live Implementation

/// Production implementation that loads data from the app bundle
struct LiveDataLoader: DataLoaderProtocol {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
    }

    func loadFillings() throws -> [Filling] {
        try loadJSON(filename: "fillings", extension: "json")
    }

    func loadCondiments() throws -> [Condiment] {
        try loadJSON(filename: "condiments", extension: "json")
    }

    func loadRecipes() throws -> [SandwichRecipe] {
        try loadJSON(filename: "sandwiches", extension: "json")
    }

    func loadMeals() throws -> [Meal] {
        try loadJSON(filename: "meals", extension: "json")
    }

    // MARK: Private Helpers

    /// Generic function to load and decode JSON files
    private func loadJSON<T: Decodable>(filename: String, extension ext: String) throws -> T {
        guard let url = bundle.url(forResource: filename, withExtension: ext) else {
            throw DataLoaderError.fileNotFound("\(filename).\(ext)")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataLoaderError.fileReadFailed("\(filename).\(ext)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DataLoaderError.decodingFailed(
                "\(filename).\(ext)",
                underlyingError: error.localizedDescription
            )
        }
    }
}

// MARK: - Unimplemented (for testing)

/// Unimplemented version that throws fatal errors - used as default testValue
struct UnimplementedDataLoader: DataLoaderProtocol {
    func loadFillings() throws -> [Filling] {
        XCTFail("DataLoader.loadFillings is unimplemented")
        return []
    }

    func loadCondiments() throws -> [Condiment] {
        XCTFail("DataLoader.loadCondiments is unimplemented")
        return []
    }

    func loadRecipes() throws -> [SandwichRecipe] {
        XCTFail("DataLoader.loadRecipes is unimplemented")
        return []
    }

    func loadMeals() throws -> [Meal] {
        XCTFail("DataLoader.loadMeals is unimplemented")
        return []
    }
}

// MARK: - TCA Dependency

private enum DataLoaderKey: DependencyKey {
    static let liveValue: any DataLoaderProtocol = LiveDataLoader()
    static let testValue: any DataLoaderProtocol = UnimplementedDataLoader()
    static let previewValue: any DataLoaderProtocol = LiveDataLoader()
}

extension DependencyValues {
    var dataLoader: DataLoaderProtocol {
        get { self[DataLoaderKey.self] }
        set { self[DataLoaderKey.self] = newValue }
    }
}
