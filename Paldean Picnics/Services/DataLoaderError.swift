//
//  DataLoaderError.swift
//  Paldean Picnics
//
//  Error types for data loading operations
//

import Foundation

/// Errors that can occur during data loading operations
enum DataLoaderError: Error, LocalizedError, Equatable {
    /// The requested JSON file could not be found in the bundle
    case fileNotFound(String)

    /// The JSON data could not be decoded into the expected model type
    case decodingFailed(String, underlyingError: String)

    /// The file was found but could not be read
    case fileReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find \(filename) in app bundle"
        case .decodingFailed(let filename, let error):
            return "Failed to decode \(filename): \(error)"
        case .fileReadFailed(let filename):
            return "Failed to read data from \(filename)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Ensure the JSON file is added to the Xcode target and included in the app bundle."
        case .decodingFailed:
            return "Check that the JSON structure matches the expected model format."
        case .fileReadFailed:
            return "Verify the file has not been corrupted."
        }
    }
}
