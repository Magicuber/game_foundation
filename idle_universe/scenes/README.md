# Game Scenes

This directory contains Godot scene files that define the visual UI and game interfaces.

## Scene Organization

- Main game scenes
- UI panels and menus
- Element selection interfaces
- Planet selection interfaces
- Upgrade shop interfaces
- Blessings display panels
- Oblation interfaces
- HUD components

## Structure

Each scene typically:
1. Defines UI layout and components
2. Connects to appropriate controllers
3. Handles user interaction events
4. Updates based on game state changes

## Integration

Scenes interact with the game through:
- Controllers that manage UI logic
- Data binding to game state
- Event callbacks for user interactions
- Refresh mechanisms when game state changes

## Design Philosophy

Scene files follow Godot's component-based architecture where:
- UI components are organized hierarchically
- Properties are bound to game state
- Controllers handle user input and update state
- Scenes are reusable and modular

This separation allows for clean separation between UI presentation and game logic.