# Tests

[Back to Project Documentation](./README.md)

## Overview

`src/tests/` holds regression and smoke tests for core game systems.

## Test pattern

Each test file usually:
1. builds fresh `GameState` with `TestSupport`
2. mutates state for scenario
3. calls system under test
4. asserts output with string failure message
5. returns empty string on pass

This is simple test runner pattern, not xUnit-style.

## Key helpers

**File:** [`src/tests/test_support.gd`](../src/tests/test_support.gd)

Helpers:
- `build_state()`
- `require_element()`
- `unlock_elements()`
- `set_element_amount()`
- `digit_equals()`

## Core suite

**File:** [`src/tests/core_regression_suite.gd`](../src/tests/core_regression_suite.gd)

Covered cases:
- save round-trip
- progression state
- upgrade aggregate
- dust recipe
- planet production
- element system
- fission overflow base output

## Smoke checks

Other files check single systems or UI-related behavior:
- blessing lifecycle
- blessings panel
- prestige flow
- save recovery
- fission pair selection
- atomic cost entries

## Output

Core suite writes report text file:
- `src/tests/core_regression_suite_report.txt`

## Why tests matter

These systems are heavily interconnected:
- upgrade effects alter smash math
- resource manager affects purchase paths
- serializer touches nearly every state object
- prestige/reset can break everything if order wrong

Tests lock those behaviors down.

## Related docs

- [Save Manager](./save_manager.md)
- [State Classes](./state_classes.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)