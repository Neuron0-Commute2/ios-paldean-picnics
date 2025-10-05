//
//  MealBrowserView.swift
//  Paldean Picnics
//
//  UI for browsing restaurant meals
//

import SwiftUI
import ComposableArchitecture

struct MealBrowserView: View {
    @Bindable var store: StoreOf<MealBrowserFeature>
    var onSelectMeal: (Meal) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading meals...")
                } else if store.filteredMeals.isEmpty && !store.searchQuery.isEmpty {
                    emptySearchState
                } else {
                    mealsList
                }
            }
            .navigationTitle("Meals")
            .searchable(text: $store.searchQuery, prompt: "Search meals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Town", selection: $store.selectedTown) {
                            ForEach(store.availableTowns, id: \.self) { town in
                                Text(town).tag(town)
                            }
                        }

                        Picker("Shop", selection: $store.selectedShop) {
                            ForEach(store.availableShops, id: \.self) { shop in
                                Text(shop).tag(shop)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
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

    // MARK: - Meals List

    private var mealsList: some View {
        List {
            if store.selectedShop != "All Shops" || store.selectedTown != "All Towns" {
                Section {
                    HStack {
                        if store.selectedTown != "All Towns" {
                            FilterChip(title: store.selectedTown) {
                                store.selectedTown = "All Towns"
                            }
                        }
                        if store.selectedShop != "All Shops" {
                            FilterChip(title: store.selectedShop) {
                                store.selectedShop = "All Shops"
                            }
                        }
                    }
                }
            }

            ForEach(store.mealsGroupedByShop, id: \.shop) { group in
                Section(group.shop) {
                    ForEach(group.meals) { meal in
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
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No meals found")
                .font(.headline)

            Text("Try a different search term or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Meal Row

struct MealRow: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)

                    Text(meal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("₽\(meal.cost)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if !meal.towns.isEmpty {
                        Text("\(meal.towns.count) town\(meal.towns.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !meal.effects.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(meal.effects) { effect in
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

#Preview {
    MealBrowserView(
        store: Store(initialState: MealBrowserFeature.State()) {
            MealBrowserFeature()
        },
        onSelectMeal: { _ in }
    )
}
