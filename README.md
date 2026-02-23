# weekPlanWatch

A watchOS SwiftUI app for weekly meal planning. Displays today's recipe on your Apple Watch — with an ingredients checklist and step-by-step cooking guide — by fetching live data from a local REST API backend.

## How it works

The app connects to a local REST API server on your network. The server holds your recipes, ingredients, and weekly meal patterns. The watch app fetches today's recipe by:

1. Loading all ingredients, recipes, patterns, and settings from the API
2. Using `Settings.patternStartDate` and `Settings.patternOrder` to determine which pattern is active this week
3. Finding the meal block that covers today (Monday = 0 … Sunday = 6)
4. Displaying that recipe's ingredients and steps

## Prerequisites

- **Mac** with Xcode 15 or later
- **Apple Watch** (paired with your iPhone) or an Apple Watch simulator
- A running instance of the **weekPlan backend** on your local network, exposing:
  - `GET /api/ingredients`
  - `GET /api/recipes`
  - `GET /api/patterns`
  - `GET /api/settings`

## Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd weekPlanWatch
```

### 2. Create your local config file

The API base URL is stored in a gitignored config file so it never gets committed.

```bash
cp Config.xcconfig.example Config.xcconfig
```

Open `Config.xcconfig` and replace `YOUR_SERVER_IP` with the IP address of your backend server:

```
SLASH = /
API_BASE_URL = http:$(SLASH)/192.168.1.100:3000/api
```

> **Note:** The `SLASH = /` workaround is required because Xcode `.xcconfig` files treat `//` as a comment. Keep that line as-is and only change the IP and port.

### 3. Open in Xcode

```bash
open weekPlanWatch.xcodeproj
```

### 4. Select a target device

In the Xcode toolbar, select either:
- **Apple Watch Simulator** — for testing without a physical device
- **Your paired Apple Watch** — for running on real hardware (requires your Apple Developer account to be signed in under *Xcode → Settings → Accounts*)

### 5. Build and run

Press **Cmd + R** or click the Run button. The app will launch on the selected watch target.

## API data format

Your backend must return JSON matching these shapes:

### `GET /api/ingredients`
```json
[
  { "id": "ing1", "name": "Onion", "unit": "pcs" }
]
```

### `GET /api/recipes`
```json
[
  {
    "id": "rec1",
    "name": "Pasta Bolognese",
    "ingredients": [
      { "ingredientId": "ing1", "quantity": 1, "unit": "pcs" }
    ],
    "steps": [
      "Chop the onion.",
      "Fry until golden.",
      "Add sauce and simmer for 20 minutes."
    ]
  }
]
```

### `GET /api/patterns`
```json
[
  {
    "id": "pat1",
    "name": "Week A",
    "mealBlocks": [
      { "id": "mb1", "recipeId": "rec1", "startDayIndex": 0, "durationDays": 2 }
    ]
  }
]
```

`startDayIndex` uses **Monday = 0, Tuesday = 1, … Sunday = 6**.
A block with `startDayIndex: 0, durationDays: 2` covers Monday and Tuesday.

### `GET /api/settings`
```json
{
  "id": "settings",
  "patternStartDate": "2024-01-01",
  "patternOrder": ["pat1", "pat2"]
}
```

- `patternStartDate` — ISO 8601 date (`YYYY-MM-DD`) of the Monday that week 0 started
- `patternOrder` — ordered list of pattern IDs; rotates week by week

## Build from the command line

```bash
# Build
xcodebuild -project weekPlanWatch.xcodeproj \
  -scheme "weekPlanWatch Watch App" \
  -configuration Debug build

# Run unit tests
xcodebuild -project weekPlanWatch.xcodeproj \
  -scheme "weekPlanWatch Watch App" test
```

## Project structure

```
weekPlanWatch Watch App/
├── weekPlanWatchApp.swift   — @main entry point
├── ContentView.swift        — root UI, drives loading state
├── IngredientsView.swift    — ingredients checklist
├── StepsView.swift          — step-by-step recipe guide
├── Models.swift             — Codable data models
└── WeekPlanService.swift    — fetches API data, resolves today's recipe
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| App crashes at launch with "API_BASE_URL not set" | `Config.xcconfig` is missing — run `cp Config.xcconfig.example Config.xcconfig` and fill in your server IP |
| Shows "Failed to load" error | Check that your backend is running and reachable from your Mac/device on the same network |
| Shows "No recipe planned for today" | Verify your `settings.patternStartDate` is correct and that your pattern has a `mealBlock` covering today's day index |
| Build error about `Config.xcconfig` | Make sure the file exists at the project root (same level as `weekPlanWatch.xcodeproj`) |
