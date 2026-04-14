# UI Controllers

This directory contains controller classes that handle UI logic and user interactions.

## Purpose

UI controllers act as intermediaries between user input and game logic. They:
- Handle UI events and user actions
- Coordinate between different game systems
- Update UI elements based on game state
- Process user input and translate it to game actions

## Controller Components

- `atom_effects_controller.gd` - Controls atom effect displays and animations
- `blessings_panel_controller.gd` - Manages blessings panel UI and interactions
- `element_menu_controller.gd` - Handles element selection and progression UI
- `era_panel_controller.gd` - Controls era selection and progression UI
- `hud_controller.gd` - Manages heads-up display elements
- `menu_controller.gd` - Handles general menu navigation and UI
- `oblations_panel_controller.gd` - Manages oblations panel and recipe interactions
- `planets_panel_controller.gd` - Controls planet selection and UI

## Architecture

Controllers receive references to relevant game state components and use them to:
1. Update UI displays
2. Handle user input
3. Trigger game logic operations
4. Manage UI state transitions

This separation helps keep UI logic separate from core game logic while maintaining clear communication between the two.