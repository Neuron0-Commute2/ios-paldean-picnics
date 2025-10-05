//
//  IngredientRow.swift
//  Paldean Picnics
//
//  Displays an ingredient with name and icon
//

import SwiftUI

struct IngredientRow: View {
    let ingredient: AnyIngredient
    var showQuantity: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder icon (will use AsyncImage when images are available)
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(typeColor)
                .frame(width: 40, height: 40)
                .background(typeColor.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(ingredient.ingredientType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let quantity = showQuantity {
                Text("×\(quantity)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch ingredient.ingredientType {
        case .filling:
            if ingredient.isHerbaMystica {
                return "sparkles"
            }
            return "fork.knife"
        case .condiment:
            if ingredient.isHerbaMystica {
                return "sparkles"
            }
            return "drop.fill"
        }
    }

    private var typeColor: Color {
        // Color based on dominant type
        if let firstType = ingredient.types.first {
            switch firstType.type {
            case .fire: return .red
            case .water: return .blue
            case .grass: return .green
            case .electric: return .yellow
            case .psychic: return .purple
            default: return .gray
            }
        }
        return .gray
    }
}

#Preview {
    VStack {
        IngredientRow(ingredient: AnyIngredient(filling: Filling(
            id: "1",
            name: "Apple",
            tastes: [FlavorValue(flavor: .sweet, amount: 4)],
            powers: [PowerValue(type: .egg, amount: 4)],
            types: [TypeValue(type: .flying, amount: 7)],
            imageUrl: "",
            pieces: 3,
            maxPiecesOnDish: 6
        )))

        IngredientRow(
            ingredient: AnyIngredient(condiment: Condiment(
                id: "2",
                name: "Butter",
                tastes: [FlavorValue(flavor: .sweet, amount: 12)],
                powers: [PowerValue(type: .exp, amount: 12)],
                types: [TypeValue(type: .bug, amount: 2)],
                imageUrl: ""
            )),
            showQuantity: 2
        )
    }
    .padding()
}
