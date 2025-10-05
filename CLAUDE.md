# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Paldean Picnics is an iOS app for Pokemon Scarlet/Violet that combines sandwich calculation and simulation. The app helps players optimize sandwich recipes to achieve desired Meal Powers and Pokemon Type bonuses using The Composable Architecture (TCA).

**Bundle ID**: `com.paldeanpicnics.ios.Paldean-Picnics`
**Platform**: iOS 26.0+
**Swift Version**: 5.0

## Building & Testing

```bash
# Build the project
xcodebuild -project "Paldean Picnics.xcodeproj" -scheme "Paldean Picnics" build

# Run tests
xcodebuild test -project "Paldean Picnics.xcodeproj" -scheme "Paldean Picnics"

# Open in Xcode
open "Paldean Picnics.xcodeproj"
```

## Architecture

This is a TCA (The Composable Architecture) app with three main modes:

1. **Calculator Mode**: Reverse-lookup using linear programming to find optimal recipes for desired powers
2. **Simulator Mode**: Build custom sandwiches with live effect calculation
3. **Recipe Browser**: Browse preset recipes and restaurant meals

### Data Flow

```
User Input → TCA Feature (State/Action/Reducer)
          ↓
     Service Layer (DataLoader, SandwichCalculator, OptimizationEngine)
          ↓
     Model Layer (Ingredient, Recipe, Calculation)
          ↓
     JSON Data (.source directories)
```

## Key Models (Phase 0 - Complete)

All foundation models are implemented in `Paldean Picnics/Models/`:

- **Enums.swift**: Core types (`Flavor`, `MealPower`, `PokemonType`, `PowerLevel`, `Currency`)
- **Ingredient.swift**: `Filling`, `Condiment`, flavor/power/type values, `SelectedIngredient`
- **Recipe.swift**: `SandwichRecipe`, `Meal`, `SandwichEffect`, `SearchTarget`
- **Calculation.swift**: `CalculatedSandwich`, `CalculatedEffect`, totals, `OptimizationResult`

### Important Model Details

- **Flavor**: 5 types (Sweet, Salty, Sour, Bitter, Spicy/Hot)
- **MealPower**: 10 types (Egg, Catch, Exp, Item, Raid, Sparkling, Title, Humungo, Teensy, Encounter)
- **PokemonType**: 18 types + "All Types"
- **PowerLevel**: 1, 2, or 3 (Lv. 1/2/3)
- **Herba Mystica**: Special condiments with bonus effects (max 2 per sandwich)

## Data Sources

The `.source/` directory contains two reference implementations:

### pokemon-sandwich-simulator
- **Purpose**: Calculation algorithm reference
- **Key Files**:
  - `src/helper/helper.js` - Core sandwich calculation logic (500+ lines)
  - `src/helper/taste-powers.json` - Flavor combination rules
  - `src/helper/skill-level-point-table.json` - Power level thresholds
  - `src/helper/deliciousness-poketype-points.json` - Type affinity calculations
  - `src/tests/*.json` - Test cases for validation

### sv-sandwich-builder
- **Purpose**: Primary data source + optimization reference
- **Key Files**:
  - `source-data/fillings.json` - All filling ingredients
  - `source-data/condiments.json` - All condiment ingredients
  - `source-data/sandwiches.json` - 151+ preset recipes
  - `source-data/meals.json` - Restaurant meals by town/shop
  - `src/data/linear-vars.json` - Linear programming variables

### Data Migration (Phase 1 - TODO)

JSON files from `.source/sv-sandwich-builder/source-data/` need to be:
1. Copied to `Resources/Data/` in the Xcode project
2. Added to target membership
3. Loaded via `DataLoader` service

## Sandwich Calculation Algorithm

The core calculation is based on `pokemon-sandwich-simulator/src/helper/helper.js`. Key concepts:

### Flavor Combination System

1. **Aggregate flavors** from all ingredients
2. **Identify top 2 flavors** (highest values)
3. **Map flavor pairs** to meal powers using `taste-powers.json`:
   - Sweet alone → Egg Power
   - Salty + Spicy → Catching Power
   - etc.

### Power Level Calculation

Power levels (1/2/3) are determined by:
1. **Flavor totals** (determines base power)
2. **Power value totals** from ingredients
3. **Type value totals** from ingredients
4. **Herba Mystica bonuses** (adds 100 to power, 180 to type)
5. **Multiplayer scaling** (higher limits = more ingredients = higher powers)

Thresholds in `skill-level-point-table.json`:
- Lv. 1: ~80-100 points
- Lv. 2: ~180-200 points
- Lv. 3: ~380-400 points

### Validation Rules

- **Fillings**: 6 pieces per player (max 24 in 4-player)
- **Condiments**: 4 per player (max 16 in 4-player)
- **Herba Mystica**: Max 2 per sandwich
- **Individual ingredient limits**: Each filling has `maxPiecesOnDish` property

## Next Implementation Steps (Phase 1)

Based on TODO.md, the next tasks are:

1. **Create DataLoader service** to load JSON files
2. **Port calculation algorithm** from `helper.js` to Swift
3. **Build TCA features** (Calculator, Simulator, RecipeBrowser)
4. **Implement optimization engine** (linear programming or heuristic search)

## Linear Programming Optimization (Phase 3)

The calculator mode uses optimization to find recipes matching user-specified targets:

**Objective**: Maximize score for desired power/type combinations
**Constraints**:
- Ingredient piece limits (6 fillings, 4 condiments per player)
- Flavor value requirements for specific powers
- Type value requirements for specific types
- Herba Mystica special rules

**Swift Options**:
- Accelerate framework (BLAS/LAPACK)
- Port simplex algorithm from `javascript-lp-solver`
- Heuristic search as fallback

## Important Calculation Details

### Herba Mystica Effects

When 2 Herba Mystica are used:
- Adds +100 to the primary meal power value
- Adds +180 to the primary type value
- This is the only way to achieve Lv. 3 powers reliably

### Multiplayer Mode

Number of players affects:
- Max ingredients (more players = more ingredients allowed)
- Power calculations (more ingredients = higher totals)
- NOT the effect duration (fixed per level)

### Bread Toggle

The `hasBread` flag affects:
- Whether base bread flavors are included in calculation
- Edge case handling for "breadless" sandwiches

## Test Data

Reference test cases in `.source/pokemon-sandwich-simulator/src/tests/`:
- `herba.json` - Herba Mystica combinations
- `multiplayer.json` - 2-4 player scenarios
- `bread-vs.json` - Bread vs no-bread comparisons
- `1-star.json`, `2-star.json`, `4-star.json` - Difficulty tiers

Use these to validate the Swift calculation engine produces identical results.

## Common Development Pitfalls

1. **Flavor enum mismatch**: Game data uses "Hot" but conceptually it's "Spicy"
2. **ID handling**: Some JSON files use numeric IDs, others use strings - models handle both
3. **Power name variations**: "Catch Power" vs "Catching Power" - use `MealPower.fullName`
4. **Type affinity**: Not all ingredients have type values, handle empty arrays
5. **Recipe numbering**: Hidden recipes use negative numbers (e.g., "-1")

## Performance Targets

- **Calculation**: < 100ms per sandwich
- **Optimization**: < 2s for complex searches
- **Data loading**: < 500ms on first launch
- **UI**: 60fps scrolling in lists

## File Structure

```
Paldean Picnics/
├── Models/              ✅ Phase 0 complete
├── Services/            ⏳ Next: DataLoader, SandwichCalculator
├── Features/            ⏸️ TCA features (App, Calculator, Simulator, etc.)
├── Components/          ⏸️ Reusable UI components
└── Resources/Data/      ⏸️ JSON data files (to be migrated)
```
