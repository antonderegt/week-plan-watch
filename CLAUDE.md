# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**weekPlanWatch** is a watchOS SwiftUI app for weekly meal planning, targeting Apple Watch. It fetches today's recipe from a local REST API and displays an ingredients checklist and step-by-step guide.

- **Bundle ID:** `com.anton.weekPlanWatch.watchkitapp`
- **Platform:** watchOS (Device Family 4)
- **Language:** Swift / SwiftUI
- **Backend API:** `http://192.168.178.169:3000/api` (local server, see `update-pi` skill to deploy)
- **API endpoints used:** `/ingredients`, `/recipes`, `/patterns`, `/settings`

## Setup

Before building, create your local config file:

```bash
cp Config.xcconfig.example Config.xcconfig
```

Edit `Config.xcconfig` and set `API_BASE_URL` to your backend server address.

## Build & Test Commands

```bash
# Build
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" -configuration Debug build

# Run unit tests
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" test

# Run a single test (replace TestClassName/testMethodName)
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" test -only-testing:weekPlanWatch\ Watch\ AppTests/TestClassName/testMethodName
```

The primary way to build and run is through Xcode with an Apple Watch simulator.

## Swift Concurrency

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in build settings — every type is implicitly `@MainActor` unless marked otherwise.
- Data model structs must be `nonisolated` (e.g. `nonisolated struct Foo: Codable, Sendable`) so their synthesized `Codable` conformances aren't `@MainActor`-isolated
- Nonisolated utility functions (e.g. network fetch) also need `nonisolated let` for any constants they access on a `@MainActor` class

## Architecture

The app uses **pure SwiftUI** with a scene-based lifecycle (no AppDelegate):

- `weekPlanWatchApp.swift` — `@main` entry point, creates a `WindowGroup` containing `ContentView`
- `ContentView.swift` — main UI view; this is where the watch app UI lives
- `Models.swift` — Codable data models: `Ingredient`, `Recipe`, `MealBlock`, `Pattern`, `Settings`, `DisplayIngredient`
- `WeekPlanService.swift` — `@MainActor ObservableObject`; fetches API data, resolves today's recipe via pattern/week rotation
- `IngredientsView.swift` — ingredients checklist view
- `StepsView.swift` — step-by-step recipe guide view

## Domain Notes

- Week starts Monday; day index: `(weekday + 5) % 7` maps Mon=0..Sun=6
- Patterns rotate by week number; `Settings.patternOrder` is an ordered list of pattern IDs
- `MealBlock.startDayIndex` + `durationDays` defines which days a recipe covers within a pattern

**Testing:**
- Unit tests use the modern **Swift Testing** framework (`@Test` attributes) in `weekPlanWatch Watch AppTests/`
- UI tests use **XCTest** in `weekPlanWatch Watch AppUITests/`
