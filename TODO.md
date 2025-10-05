# Paldean Picnics - Implementation TODO

A comprehensive Pokemon Scarlet/Violet sandwich calculator and simulator app for iOS using The Composable Architecture (TCA).

## 📋 Project Overview

This app combines functionality from two web projects:
- **pokemon-sandwich-simulator**: Interactive sandwich builder with real-time calculation
- **sv-sandwich-builder**: Reverse-lookup calculator with linear programming optimization

### Core Features
- 🔍 **Calculator Mode**: Search by desired powers → get optimized recipes
- 🥪 **Simulator Mode**: Build custom sandwiches with live effect preview
- 📖 **Recipe Browser**: View all preset sandwich recipes from the game
- 🍽️ **Meal Database**: Browse restaurant meals by town/shop
- 👥 **Multiplayer Support**: 1-4 player mega sandwiches
- ⚡ **Optimization**: LP solver for finding optimal ingredient combinations

---

## ✅ Phase 0: Foundation (COMPLETED)

### Models Created
- [x] `Enums.swift` - Core enumerations (Flavor, MealPower, PokemonType, Currency, etc.)
- [x] `Ingredient.swift` - Filling, Condiment, and ingredient protocols
- [x] `Recipe.swift` - SandwichRecipe, Meal, SandwichEffect models
- [x] `Calculation.swift` - CalculatedSandwich, effects, totals, optimization results

---

## 📦 Phase 1: Data Layer

### 1.1 Data Files Migration
- [x] Create `Resources/Data/` directory in Xcode project
- [x] Port `fillings.json` from `.source/sv-sandwich-builder/source-data/`
- [x] Port `condiments.json` from `.source/sv-sandwich-builder/source-data/`
- [x] Port `sandwiches.json` from `.source/sv-sandwich-builder/source-data/`
- [x] Port `meals.json` from `.source/sv-sandwich-builder/source-data/`
- [x] Create combined/consolidated JSON if data differs between repos
- [x] **Add JSON files to Xcode target membership**

### 1.2 Data Loading Service
- [x] Create `DataLoader.swift` service class
  - [x] `loadFillings() -> [Filling]` - Load and decode fillings.json
  - [x] `loadCondiments() -> [Condiment]` - Load and decode condiments.json
  - [x] `loadRecipes() -> [SandwichRecipe]` - Load and decode sandwiches.json
  - [x] `loadMeals() -> [Meal]` - Load and decode meals.json
  - [x] Error handling for missing/malformed JSON
  - [x] Error logging and UI alerts
  - [x] Fixed SandwichEffect decoding (empty string → .allTypes)
  - [ ] Unit tests for data loading

### 1.3 Data Validation
- [ ] Cross-reference ingredient names in recipes with actual ingredient data
- [ ] Validate all image URLs are accessible
- [ ] Verify effect calculations match expected values from source data
- [ ] Create test sandwich calculations and compare with web versions

---

## 🧮 Phase 2: Calculation Engine

### 2.1 Core Algorithm (from pokemon-sandwich-simulator/helper.js)
- [ ] Create `SandwichCalculator.swift` service
  - [ ] Port `getSandwich()` function - Main calculation entry point
  - [ ] Port flavor combination logic (TASTE_POWERS, TASTE_MAP)
  - [ ] Port skill level point tables (SKILL_LEVEL_POINT_TABLE)
  - [ ] Port deliciousness/type points (DELICIOUSNESS_POKETYPE_POINTS)
  - [ ] Implement Herba Mystica bonus calculations
  - [ ] Implement multiplayer scaling (1-4 players)
  - [ ] Handle bread presence/absence

### 2.2 Helper Functions
- [ ] `calculateFlavorTotals()` - Aggregate flavor values from ingredients
- [ ] `calculatePowerTotals()` - Aggregate meal power values
- [ ] `calculateTypeTotals()` - Aggregate type affinity values
- [ ] `determineMealPowersFromFlavors()` - Apply flavor combination rules
- [ ] `calculateEffectLevels()` - Convert raw values to Lv 1/2/3
- [ ] `matchPresetRecipe()` - Check if custom sandwich matches a preset

### 2.3 Validation & Edge Cases
- [ ] Handle zero-ingredient sandwiches
- [ ] Handle single-ingredient edge cases
- [ ] Handle max Herba Mystica (2 max per sandwich)
- [ ] Validate piece counts vs max allowed
- [ ] Handle tie-breaking in flavor/type calculations

### 2.4 Testing
- [ ] Unit tests for each calculation function
- [ ] Integration tests with known recipes
- [ ] Test all 151+ preset recipes calculate correctly
- [ ] Performance tests for large ingredient sets

---

## 🔬 Phase 3: Optimization Engine (Linear Programming)

### 3.1 Research & Dependencies
- [ ] Research Swift LP solver libraries (e.g., SwiftNumerics, Accelerate framework)
- [ ] Evaluate alternatives: port JS solver vs use native Swift library
- [ ] Document chosen approach and trade-offs

### 3.2 LP Solver Implementation
- [ ] Create `OptimizationEngine.swift`
  - [ ] Define constraint types (LinearConstraints model)
  - [ ] Implement objective function (maximize power/type values)
  - [ ] Implement constraints:
    - [ ] Piece limits (6 fillings, 4 condiments per player)
    - [ ] Flavor value constraints
    - [ ] Meal power value constraints
    - [ ] Type value constraints
    - [ ] Herba Mystica special constraints
  - [ ] Solver execution and result parsing

### 3.3 Search Algorithm
- [ ] `searchRecipes(targets: [SearchTarget]) -> [OptimizationResult]`
  - [ ] Convert user targets to LP constraints
  - [ ] Run optimization
  - [ ] Rank results by score
  - [ ] Filter by validity (achievable with available ingredients)
- [ ] Handle multiple target powers simultaneously
- [ ] Implement fallback heuristics if LP fails

### 3.4 Testing
- [ ] Test known optimal recipes from web version
- [ ] Test edge cases (impossible combinations)
- [ ] Performance benchmarks for search speed
- [ ] Compare results with sv-sandwich-builder web version

---

## 🏗️ Phase 4: TCA Features

### 4.1 App Architecture
- [ ] Create `AppFeature.swift` - Root TCA feature
  - [ ] State: current tab, shared data
  - [ ] Actions: tab switching, data loading
  - [ ] Reducer: coordinate child features
- [ ] Create `AppView.swift` - Root SwiftUI view with TabView

### 4.2 Calculator Feature
- [x] Create `CalculatorFeature.swift`
  - [x] State:
    - [x] Selected search targets (powers + types)
    - [x] Search results (recipes/meals)
    - [x] Loading states
  - [x] Actions:
    - [x] Add/remove search target
    - [x] Execute search (filter-based, no LP solver needed)
    - [x] Select result
    - [x] Clear search
  - [x] Reducer:
    - [x] Handle search execution (async effect)
    - [x] Filter recipes/meals by matching ALL targets
    - [x] Navigate to simulator with result
  - [x] Dependencies:
    - [x] DataLoader

- [x] Create `CalculatorView.swift`
  - [x] Search target selector (power + type pickers)
  - [x] Add target button
  - [x] Target list with remove buttons
  - [x] Search button
  - [x] Results list (recipes + meals)
  - [x] Result cards with effects preview
  - [x] "Simulate" button on each result

### 4.3 Simulator Feature
- [ ] Create `SimulatorFeature.swift`
  - [ ] State:
    - [ ] Available fillings/condiments
    - [ ] Selected ingredients with quantities
    - [ ] Calculated effects
    - [ ] Matched recipe (if any)
    - [ ] Number of players (1-4)
    - [ ] Has bread toggle
    - [ ] Validation errors
  - [ ] Actions:
    - [ ] Add/remove ingredient
    - [ ] Change ingredient quantity
    - [ ] Toggle multiplayer mode
    - [ ] Toggle bread
    - [ ] Recalculate effects
    - [ ] Clear sandwich
    - [ ] Load preset recipe
  - [ ] Reducer:
    - [ ] Handle ingredient changes
    - [ ] Trigger recalculation (debounced effect)
    - [ ] Update validation state
    - [ ] Check for recipe matches
  - [ ] Dependencies:
    - [ ] SandwichCalculator
    - [ ] DataLoader

- [ ] Create `SimulatorView.swift`
  - [ ] Ingredient picker (searchable, categorized)
  - [ ] Selected ingredients list with quantity steppers
  - [ ] Effects preview card (live updating)
  - [ ] Multiplayer/bread toggles
  - [ ] Validation warnings
  - [ ] Matched recipe banner
  - [ ] Clear/reset button

### 4.4 Recipe Browser Feature
- [ ] Create `RecipeBrowserFeature.swift`
  - [ ] State:
    - [ ] All recipes
    - [ ] Search query
    - [ ] Filter options (by power, type, location)
    - [ ] Selected recipe
  - [ ] Actions:
    - [ ] Update search query
    - [ ] Toggle filters
    - [ ] Select recipe
    - [ ] Load recipe in simulator
  - [ ] Reducer:
    - [ ] Filter recipes based on query/filters
    - [ ] Navigate to detail/simulator

- [ ] Create `RecipeBrowserView.swift`
  - [ ] Search bar
  - [ ] Filter chips (powers, types, locations)
  - [ ] Recipe grid/list
  - [ ] Recipe cards with thumbnail & effects

### 4.5 Recipe Detail Feature
- [ ] Create `RecipeDetailFeature.swift`
  - [ ] State:
    - [ ] Recipe details
    - [ ] Ingredient details (loaded from IDs)
  - [ ] Actions:
    - [ ] Simulate recipe
    - [ ] Share recipe
    - [ ] Favorite recipe (future)
  - [ ] Reducer:
    - [ ] Load full ingredient data
    - [ ] Navigate to simulator

- [ ] Create `RecipeDetailView.swift`
  - [ ] Recipe image
  - [ ] Recipe name & description
  - [ ] Ingredients list with icons
  - [ ] Effects list
  - [ ] Location info
  - [ ] "Simulate This Recipe" button

### 4.6 Meal Browser Feature
- [x] Create `MealBrowserFeature.swift`
  - [x] State:
    - [x] All meals
    - [x] Search query
    - [x] Town filter
    - [x] Shop filter
  - [x] Actions:
    - [x] Update search
    - [x] Filter by town/shop
    - [x] Select meal
  - [x] Reducer:
    - [x] Filter meals
    - [x] Load data from DataLoader

- [x] Create `MealBrowserView.swift`
  - [x] Search bar
  - [x] Town/shop filter pickers (in toolbar menu)
  - [x] Meals list grouped by shop
  - [x] Meal cards with cost & effects

### 4.7 Settings Feature
- [ ] Create `SettingsFeature.swift`
  - [ ] State:
    - [ ] Default player count
    - [ ] Show hidden recipes toggle
    - [ ] Theme preferences (future)
  - [ ] Actions:
    - [ ] Update settings
  - [ ] Reducer:
    - [ ] Persist settings (UserDefaults)

- [ ] Create `SettingsView.swift`
  - [ ] Player count picker
  - [ ] Hidden recipes toggle
  - [ ] About/credits section

---

## 🎨 Phase 5: UI/UX Polish

### 5.1 Design System
- [ ] Define color palette (Pokemon S/V themed)
- [ ] Create reusable UI components:
  - [ ] `IngredientCard` - Show ingredient with icon & stats
  - [ ] `EffectBadge` - Display meal power with type & level
  - [ ] `RecipeCard` - Compact recipe preview
  - [ ] `SearchTargetChip` - Removable search target
  - [ ] `PowerLevelIndicator` - Visual Lv 1/2/3 indicator
  - [ ] `ValidationBanner` - Warning/error messages

### 5.2 Images & Assets
- [ ] Download ingredient images from both repos' public folders
- [ ] Add to Xcode asset catalog
- [ ] Create fallback placeholder images
- [ ] Optimize image sizes for iOS
- [ ] Add app icon

### 5.3 Animations & Transitions
- [ ] Add smooth transitions between calculator ↔ simulator
- [ ] Animate effect calculations
- [ ] Loading states with activity indicators
- [ ] Success/error feedback animations

### 5.4 Accessibility
- [ ] VoiceOver labels for all interactive elements
- [ ] Dynamic Type support
- [ ] Color contrast validation
- [ ] Keyboard navigation (iPad)

---

## 🧪 Phase 6: Testing

### 6.1 Unit Tests
- [ ] Model tests (Codable conformance, computed properties)
- [ ] Calculator tests (all edge cases)
- [ ] Optimization tests (known optimal solutions)
- [ ] Data loader tests

### 6.2 TCA Integration Tests
- [ ] Calculator feature tests
- [ ] Simulator feature tests
- [ ] Navigation flow tests
- [ ] State persistence tests

### 6.3 UI Tests
- [ ] End-to-end user flows
- [ ] Search → result → simulate flow
- [ ] Recipe browser → detail → simulate flow
- [ ] Accessibility tests

### 6.4 Performance Tests
- [ ] Calculation speed benchmarks
- [ ] Optimization solver performance
- [ ] Large dataset filtering
- [ ] Memory profiling

---

## 🚀 Phase 7: Launch Preparation

### 7.1 Documentation
- [ ] README.md with app description
- [ ] User guide (in-app help)
- [ ] Code documentation (DocC)
- [ ] Credits for data sources

### 7.2 App Store Assets
- [ ] App Store screenshots
- [ ] App preview video
- [ ] App description
- [ ] Keywords
- [ ] Privacy policy

### 7.3 Beta Testing
- [ ] TestFlight setup
- [ ] Beta tester recruitment
- [ ] Bug tracking
- [ ] Feedback iteration

---

## 🔮 Future Enhancements (Phase 8+)

### Advanced Features
- [ ] Save custom sandwiches (local storage)
- [ ] Share recipes via link/QR code
- [ ] Compare two recipes side-by-side
- [ ] Ingredient substitution suggestions
- [ ] "Surprise Me" random sandwich generator
- [ ] Integration with Pokemon team builders (show recommended powers)

### Multiplayer Enhancements
- [ ] Visual indication of which player adds which ingredient
- [ ] Split ingredient picker by player
- [ ] Multiplayer coordination tips

### Data Updates
- [ ] Support for DLC ingredients (if any)
- [ ] Community recipe submissions
- [ ] Cloud sync of favorites

### Platform Expansion
- [ ] iPad optimization (multi-column layout)
- [ ] macOS app (Catalyst or native)
- [ ] Widget support (quick recipe lookup)

---

## 📊 Known Challenges & Solutions

### Challenge 1: Linear Programming in Swift
**Problem**: JavaScript `javascript-lp-solver` library doesn't exist in Swift
**Solutions**:
- Option A: Use Accelerate framework's BLAS/LAPACK for matrix operations
- Option B: Use third-party Swift optimization library (e.g., SwiftNumerics)
- Option C: Port the simplex algorithm from JS to Swift manually
- Option D: Hybrid approach - use heuristic search instead of pure LP

**Recommendation**: Start with Option D (heuristic), add proper LP later if needed

### Challenge 2: Complex Calculation Algorithm
**Problem**: helper.js has 500+ lines of intertwined calculation logic
**Solutions**:
- Break into small, testable functions
- Use TDD approach (write tests first based on known recipes)
- Cross-validate with web version using same inputs

### Challenge 3: Large Dataset Performance
**Problem**: 60+ fillings, 22 condiments, 151+ recipes, 150+ meals
**Solutions**:
- Index data structures for O(1) lookups
- Use lazy loading for images
- Implement efficient filtering (pre-computed indexes)
- Debounce search/recalculation

### Challenge 4: Ingredient Image Loading
**Problem**: Images are hosted on external URLs (serebii.net)
**Solutions**:
- Download and bundle images locally
- Implement caching layer for network images
- Use placeholder images for failed loads
- Consider legal/permission for redistribution

---

## 🗂️ File Structure

```
Paldean Picnics/
├── Models/
│   ├── Enums.swift ✅
│   ├── Ingredient.swift ✅
│   ├── Recipe.swift ✅
│   └── Calculation.swift ✅
├── Services/
│   ├── DataLoader.swift
│   ├── SandwichCalculator.swift
│   └── OptimizationEngine.swift
├── Features/
│   ├── App/
│   │   ├── AppFeature.swift
│   │   └── AppView.swift
│   ├── Calculator/
│   │   ├── CalculatorFeature.swift
│   │   └── CalculatorView.swift
│   ├── Simulator/
│   │   ├── SimulatorFeature.swift
│   │   └── SimulatorView.swift
│   ├── RecipeBrowser/
│   │   ├── RecipeBrowserFeature.swift
│   │   ├── RecipeBrowserView.swift
│   │   ├── RecipeDetailFeature.swift
│   │   └── RecipeDetailView.swift
│   ├── MealBrowser/
│   │   ├── MealBrowserFeature.swift
│   │   └── MealBrowserView.swift
│   └── Settings/
│       ├── SettingsFeature.swift
│       └── SettingsView.swift
├── Components/
│   ├── IngredientCard.swift
│   ├── EffectBadge.swift
│   ├── RecipeCard.swift
│   ├── SearchTargetChip.swift
│   └── ValidationBanner.swift
├── Resources/
│   ├── Data/
│   │   ├── fillings.json
│   │   ├── condiments.json
│   │   ├── sandwiches.json
│   │   └── meals.json
│   └── Images/
│       ├── Ingredients/
│       └── Meals/
└── Tests/
    ├── ModelTests/
    ├── CalculatorTests/
    ├── OptimizationTests/
    └── FeatureTests/
```

---

## 📝 Notes

### Data Consolidation Status
- Using `sv-sandwich-builder/source-data/` as primary data source (cleaner structure)
- Algorithm logic from `pokemon-sandwich-simulator/src/helper/helper.js`
- Cross-reference both sources to ensure data completeness

### TCA Best Practices
- Keep features small and focused
- Use `@Dependency` for services (DataLoader, Calculator, etc.)
- Implement `Equatable` on State for performance
- Use `EffectTask` for async operations
- Write tests for all reducers

### Performance Targets
- Calculation: < 100ms for any sandwich
- Optimization: < 2s for complex searches
- Data load: < 500ms on first launch
- UI responsiveness: 60fps scrolling

---

## 🎯 Current Status

**Phase 0**: ✅ COMPLETE (Models)
**Phase 1**: ✅ COMPLETE (Data Layer - JSON loading working!)
**Phase 2**: ✅ COMPLETE (Calculation Engine)
**Phase 3**: ⏸️ SKIPPED (Optimization - future enhancement)
**Phase 4**: ✅ COMPLETE (UI/TCA Features - ALL 4 TABS!)
  - ✅ Simulator (build sandwiches)
  - ✅ Calculator (search by desired effects)
  - ✅ Recipe Browser (browse preset recipes)
  - ✅ Meal Browser (browse restaurant meals)

**Status**: 🚀 **FULLY FUNCTIONAL APP!**
- ✅ 4-tab navigation
- ✅ Search recipes/meals by desired powers & types
- ✅ Browse all recipes and meals
- ✅ Build custom sandwiches with live calculations
- ✅ Town/shop filters for meals

**Next Steps**:
1. Test new features (Calculator, Meal Browser)
2. UI Polish (better components, animations)
3. Images/Assets (ingredient images, app icon)

**Last Updated**: 2025-10-04
