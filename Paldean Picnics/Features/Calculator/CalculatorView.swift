//
//  CalculatorView.swift
//  Paldean Picnics
//
//  UI for reverse-lookup calculator (find recipes by desired effects)
//

import SwiftUI
import ComposableArchitecture

struct CalculatorView: View {
    @Bindable var store: StoreOf<CalculatorFeature>
    var onSelectRecipe: (SandwichRecipe) -> Void
    var onSelectMeal: (Meal) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading data...")
                } else {
                    calculatorContent
                }
            }
            .navigationTitle("Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.hasTargets {
                        Button("Clear All") {
                            store.send(.clearAll)
                        }
                    }
                }
            }
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

    // MARK: - Calculator Content

    private var calculatorContent: some View {
        List {
            // Target Builder
            Section("Add Search Target") {
                Picker("Power", selection: $store.selectedPower) {
                    ForEach(MealPower.allCases, id: \.self) { power in
                        Text(power.fullName).tag(power)
                    }
                }

                Picker("Type", selection: $store.selectedType) {
                    Text("Any Type").tag(PokemonType.allTypes)
                    ForEach(PokemonType.allCases.filter { $0 != .allTypes }, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                Picker("Min Level", selection: $store.selectedMinLevel) {
                    ForEach(PowerLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Button(action: { store.send(.addTarget) }) {
                    Label("Add Target", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            // Current Targets
            if store.hasTargets {
                Section("Search Targets") {
                    ForEach(store.searchTargets) { target in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(target.mealPower.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                HStack(spacing: 8) {
                                    Text(target.minLevel.displayName + "+")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)

                                    if target.type != .allTypes {
                                        Text(target.type.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Any Type")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: { store.send(.removeTarget(id: target.id)) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button(action: { store.send(.executeSearch) }) {
                        HStack {
                            Spacer()
                            if store.isSearching {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(store.isSearching ? "Searching..." : "Search")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isSearching)
                }
            }

            // Results
            if store.hasResults {
                if !store.matchingRecipes.isEmpty {
                    Section("Matching Recipes (\(store.matchingRecipes.count))") {
                        ForEach(store.matchingRecipes) { recipe in
                            Button {
                                store.send(.selectRecipe(recipe))
                                onSelectRecipe(recipe)
                            } label: {
                                RecipeResultRow(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !store.matchingMeals.isEmpty {
                    Section("Matching Meals (\(store.matchingMeals.count))") {
                        ForEach(store.matchingMeals) { meal in
                            Button {
                                store.send(.selectMeal(meal))
                                onSelectMeal(meal)
                            } label: {
                                MealRow(meal: meal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !store.suggestedSandwiches.isEmpty {
                    Section("Custom Sandwiches (\(store.suggestedSandwiches.count))") {
                        ForEach(store.suggestedSandwiches) { sandwich in
                            SuggestedSandwichRow(sandwich: sandwich)
                        }
                    }
                }
            } else if store.hasTargets && !store.isSearching {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("Tap 'Search' to find matching recipes and meals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Recipe Result Row

struct RecipeResultRow: View {
    let recipe: SandwichRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)

                    Text(recipe.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Suggested Sandwich Row

struct SuggestedSandwichRow: View {
    let sandwich: CalculatedSandwich

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Fillings
            VStack(alignment: .leading, spacing: 4) {
                Text("Fillings:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(sandwich.fillings, id: \.ingredient.id) { selected in
                    HStack {
                        Text(selected.ingredient.name)
                            .font(.subheadline)
                        if selected.quantity > 1 {
                            Text("x\(selected.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Condiments
            VStack(alignment: .leading, spacing: 4) {
                Text("Condiments:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(sandwich.condiments, id: \.ingredient.id) { selected in
                    Text(selected.ingredient.name)
                        .font(.subheadline)
                }
            }

            // Effects
            if !sandwich.effects.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sandwich.effects) { effect in
                            EffectBadge(effect: effect)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CalculatorView(
        store: Store(initialState: CalculatorFeature.State()) {
            CalculatorFeature()
        },
        onSelectRecipe: { _ in },
        onSelectMeal: { _ in }
    )
}
