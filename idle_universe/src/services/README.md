# Game Services

This directory contains service classes that provide utility functionality and cross-cutting concerns for the game.

## Purpose

Services provide reusable functionality that can be used across different parts of the game system:

- Utility functions
- Helper classes
- Cross-functional operations
- Game logic that doesn't fit into managers or state classes

## Current Services

The services directory currently contains utility components for:
- Game state management
- Data processing
- UI-related operations
- Game logic helpers

## Architecture

Services are lightweight components that:
1. Provide static or instance methods
2. Can be referenced by multiple managers or controllers
3. Encapsulate reusable logic
4. Don't hold game state themselves

Services help reduce code duplication and provide centralized locations for shared functionality.