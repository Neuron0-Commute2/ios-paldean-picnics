//
//  SandwichEffectsCard.swift
//  Paldean Picnics
//
//  Displays calculated sandwich effects
//

import SwiftUI

struct SandwichEffectsCard: View {
    let sandwich: CalculatedSandwich

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sandwich Effects")
                        .font(.headline)

                    if let matchedRecipe = sandwich.matchedRecipe {
                        Text(matchedRecipe.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Custom Sandwich")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Player count badge
                if sandwich.numberOfPlayers > 1 {
                    Text("\(sandwich.numberOfPlayers)P")
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
            if sandwich.effects.isEmpty {
                Text("No effects")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sandwich.effects) { effect in
                        EffectBadge(effect: effect)
                    }
                }
            }

            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fillings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(sandwich.totalFillingPieces)/\(sandwich.maxFillings)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(sandwich.totalFillingPieces > sandwich.maxFillings ? .red : .primary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Condiments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(sandwich.totalCondiments)/\(sandwich.maxCondiments)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(sandwich.totalCondiments > sandwich.maxCondiments ? .red : .primary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bread")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: sandwich.hasBread ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(sandwich.hasBread ? .green : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        SandwichEffectsCard(sandwich: CalculatedSandwich(
            fillings: [
                SelectedIngredient(ingredient: AnyIngredient(filling: Filling(
                    id: "1",
                    name: "Rice",
                    tastes: [],
                    powers: [],
                    types: [],
                    imageUrl: "",
                    pieces: 1,
                    maxPiecesOnDish: 6
                )), quantity: 5)
            ],
            condiments: [
                SelectedIngredient(ingredient: AnyIngredient(condiment: Condiment(
                    id: "2",
                    name: "Sour Herba Mystica",
                    tastes: [],
                    powers: [],
                    types: [],
                    imageUrl: ""
                )), quantity: 1)
            ],
            effects: [
                CalculatedEffect(
                    mealPower: .sparkling,
                    type: .dragon,
                    level: .three,
                    rawPowerValue: 400,
                    rawTypeValue: 400
                ),
                CalculatedEffect(
                    mealPower: .title,
                    type: .normal,
                    level: .three,
                    rawPowerValue: 380,
                    rawTypeValue: 380
                )
            ],
            matchedRecipe: nil,
            numberOfPlayers: 1,
            hasBread: true
        ))

        SandwichEffectsCard(sandwich: CalculatedSandwich(
            fillings: [],
            condiments: [],
            effects: [],
            matchedRecipe: nil,
            numberOfPlayers: 4,
            hasBread: false
        ))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
