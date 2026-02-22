# Design: Externalize Backend URL via xcconfig

**Date:** 2026-02-23
**Status:** Approved

## Problem

`WeekPlanService.swift` hardcodes `http://192.168.178.169:3000/api`. This leaks a private network address into git and prevents other contributors from using their own backend.

## Solution

Use the Apple-standard `xcconfig` + `Info.plist` pattern to inject the URL as a build setting.

## Files

| File | Action | Committed? |
|------|--------|-----------|
| `Config.xcconfig` | New — contains real URL | No (gitignored) |
| `Config.xcconfig.example` | New — contains placeholder URL | Yes |
| `weekPlanWatch Watch App/Info.plist` | Add `API_BASE_URL = $(API_BASE_URL)` key | Yes |
| `WeekPlanService.swift` | Read URL from `Bundle.main.infoDictionary` | Yes |
| `.gitignore` | Add `Config.xcconfig` | Yes |
| `weekPlanWatch.xcodeproj/project.pbxproj` | Wire xcconfig to Watch App target (Debug + Release) | Yes |

## Runtime Flow

```
Config.xcconfig
  → Xcode build setting: API_BASE_URL
  → Info.plist interpolation: $(API_BASE_URL)
  → Bundle.main.infoDictionary["API_BASE_URL"]
  → WeekPlanService.baseURL
```

## Contributor Setup

```bash
cp Config.xcconfig.example Config.xcconfig
# Edit Config.xcconfig and set API_BASE_URL to your server
```

## Error Handling

If `API_BASE_URL` is missing from `Info.plist` at runtime, `WeekPlanService` crashes with a clear `fatalError` message rather than silently failing with a bad URL.
