//
//  RecipeBrowserView.swift
//  Paldean Picnics
//
//  UI for browsing preset recipes
//

import SwiftUI
import ComposableArchitecture

struct RecipeBrowserView: View {
    @Bindable var store: StoreOf<RecipeBrowserFeature>
    var onSelectRecipe: (SandwichRecipe) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading recipes...")
                } else if store.filteredRecipes.isEmpty && !store.searchQuery.isEmpty {
                    emptySearchState
                } else {
                    recipeList
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $store.searchQuery)
            .alert("Data Loading Error", isPresented: .constant(store.dataError != nil)) {
                Button("OK", role: .cancel) {
                    store.dataError = nil
                }
            } message: {
                if let error = store.dataError {
                    Text(error)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - Recipe List

    private var recipeList: some View {
        List(store.filteredRecipes) { recipe in
            Button {
                store.send(.selectRecipe(recipe))
                onSelectRecipe(recipe)
            } label: {
                RecipeCard(recipe: recipe)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    } 

    // MARK: - Empty State

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No recipes found")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: SandwichRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)

                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if let number = recipe.recipeNumber {
                    Text("#\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }

            // Effects
            if !recipe.effects.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.effects) { effect in
                            EffectBadge(effect: CalculatedEffect(
                                mealPower: effect.mealPower ?? .egg,
                                type: effect.type,
                                level: effect.level,
                                rawPowerValue: 0,
                                rawTypeValue: 0
                            ))
                        }
                    }
                }
            }

            // Location
            if !recipe.location.isEmpty && recipe.location != "Unavailable" {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.secondary)
                    Text(recipe.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    RecipeBrowserView(
        store: Store(initialState: RecipeBrowserFeature.State()) {
            RecipeBrowserFeature()
        },
        onSelectRecipe: { _ in }
    )
}
