//
//  SimulatorView.swift
//  Paldean Picnics
//
//  UI for sandwich simulator
//

import SwiftUI
import ComposableArchitecture

struct SimulatorView: View {
    @Bindable var store: StoreOf<SimulatorFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Effects Card (sticky at top)
                if let sandwich = store.calculatedSandwich {
                    SandwichEffectsCard(sandwich: sandwich)
                        .padding()
                } else {
                    emptyStateCard
                }

                Divider()

                // Main content
                if store.isLoading {
                    ProgressView("Loading ingredients...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Sandwich Simulator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
            .alert("Validation Error", isPresented: .constant(store.validationMessage != nil)) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = store.validationMessage {
                    Text(message)
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

    // MARK: - Main Content

    private var mainContent: some View {
        List {
            // Controls Section
            Section("Settings") {
                Picker("Players", selection: $store.numberOfPlayers) {
                    ForEach(1...4, id: \.self) { count in
                        Text("\(count) Player\(count > 1 ? "s" : "")").tag(count)
                    }
                }

                Toggle("Include Bread", isOn: $store.hasBread)
            }

            // Selected Ingredients
            if !store.selectedFillings.isEmpty || !store.selectedCondiments.isEmpty {
                Section("Selected Ingredients") {
                    ForEach(store.selectedFillings) { selected in
                        HStack {
                            IngredientRow(
                                ingredient: selected.ingredient,
                                showQuantity: selected.quantity
                            )

                            Stepper("", value: Binding(
                                get: { selected.quantity },
                                set: { newValue in
                                    store.send(.updateQuantity(id: selected.id, quantity: newValue))
                                }
                            ), in: 1...12)
                            .labelsHidden()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.send(.removeIngredient(id: selected.id))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    ForEach(store.selectedCondiments) { selected in
                        IngredientRow(ingredient: selected.ingredient)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.send(.removeIngredient(id: selected.id))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // Add Ingredients
            Section {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search ingredients", text: $store.searchQuery)
                        .textFieldStyle(.plain)
                    if !store.searchQuery.isEmpty {
                        Button(action: { store.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Fillings
            if !store.filteredFillings.isEmpty {
                Section("Fillings") {
                    ForEach(store.filteredFillings, id: \.id) { filling in
                        Button {
                            store.send(.addFilling(filling))
                        } label: {
                            IngredientRow(ingredient: AnyIngredient(filling: filling))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Condiments
            if !store.filteredCondiments.isEmpty {
                Section("Condiments") {
                    ForEach(store.filteredCondiments, id: \.id) { condiment in
                        Button {
                            store.send(.addCondiment(condiment))
                        } label: {
                            IngredientRow(ingredient: AnyIngredient(condiment: condiment))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("Build Your Sandwich")
                .font(.headline)

            Text("Select ingredients below to start")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button {
            store.send(.clearSandwich)
        } label: {
            Image(systemName: "trash")
        }
        .disabled(store.selectedFillings.isEmpty && store.selectedCondiments.isEmpty)
    }
}

#Preview {
    SimulatorView(store: Store(initialState: SimulatorFeature.State()) {
        SimulatorFeature()
    })
}
