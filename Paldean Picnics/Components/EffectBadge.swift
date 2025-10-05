//
//  EffectBadge.swift
//  Paldean Picnics
//
//  Displays a meal power effect with type and level
//

import SwiftUI

struct EffectBadge: View {
    let effect: CalculatedEffect

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(effect.mealPower.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(effect.level.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelColor.opacity(0.2))
                    .foregroundColor(levelColor)
                    .cornerRadius(4)
            }

            if effect.type != .allTypes {
                Text(effect.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(typeColor.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(typeColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var typeColor: Color {
        switch effect.type {
        case .fire: return .red
        case .water: return .blue
        case .grass: return .green
        case .electric: return .yellow
        case .psychic: return .purple
        case .ice: return .cyan
        case .dragon: return .indigo
        case .dark: return .black
        case .fairy: return .pink
        case .fighting: return .orange
        case .flying: return .teal
        case .poison: return .purple
        case .ground: return .brown
        case .rock: return .gray
        case .bug: return .green
        case .ghost: return .purple
        case .steel: return .gray
        case .normal, .allTypes: return .gray
        }
    }

    private var levelColor: Color {
        switch effect.level {
        case .one: return .blue
        case .two: return .orange
        case .three: return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        EffectBadge(effect: CalculatedEffect(
            mealPower: .sparkling,
            type: .dragon,
            level: .three,
            rawPowerValue: 400,
            rawTypeValue: 400
        ))

        EffectBadge(effect: CalculatedEffect(
            mealPower: .egg,
            type: .allTypes,
            level: .two,
            rawPowerValue: 250,
            rawTypeValue: 250
        ))

        EffectBadge(effect: CalculatedEffect(
            mealPower: .encounter,
            type: .water,
            level: .one,
            rawPowerValue: 100,
            rawTypeValue: 100
        ))
    }
    .padding()
}
