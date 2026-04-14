# Test Suite

This directory contains automated tests for the Idle Universe game logic.

## Test Files

| Test | Purpose |
|------|---------|
| `core_regression_suite.gd` | Main test suite covering core game systems |
| `atomic_cost_entries_check.gd` | Tests atomic cost checking and spending |
| `blessing_lifecycle_smoke_check.gd` | Tests blessing generation and lifecycle |
| `blessings_panel_check.gd` | Tests blessings panel UI logic |
| `fission_pair_pick_check.gd` | Tests fission split element selection |
| `prestige_smoke_check.gd` | Tests prestige system functionality |
| `save_manager_recovery_check.gd` | Tests save/load error recovery |
| `test_support.gd` | Shared test utilities and helpers |

## Running Tests

Tests are run through Godot's test runner or the game's test harness. Each test file:
1. Sets up isolated game state
2. Executes test scenarios
3. Asserts expected outcomes
4. Reports pass/fail status

## Test Coverage

The test suite covers:
- Game state initialization
- Resource management
- Blessing generation
- Fission mechanics
- Save/load robustness
- Prestige system
- Cost calculations

## Adding Tests

To add a new test:
1. Create a `.gd` file extending `test_support`
2. Add test methods following naming convention
3. Use assertion functions
4. Document test purpose in comments