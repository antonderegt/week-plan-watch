# xcconfig Backend URL Configuration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the hardcoded `baseURL` in `WeekPlanService.swift` into a gitignored `Config.xcconfig` file so the private server IP is never committed.

**Architecture:** `Config.xcconfig` defines `API_BASE_URL` and `INFOPLIST_KEY_API_BASE_URL = $(API_BASE_URL)`. The xcconfig is wired as the base build configuration for the Watch App target in `project.pbxproj`. Xcode's auto-generated Info.plist picks up `INFOPLIST_KEY_*` settings at build time, so `Bundle.main.infoDictionary["API_BASE_URL"]` returns the value at runtime.

**Tech Stack:** Swift 5, SwiftUI, watchOS, Xcode xcconfig, `Bundle.main.infoDictionary`

---

### Task 1: Create Config.xcconfig.example and update .gitignore

**Files:**
- Create: `Config.xcconfig.example`
- Create: `Config.xcconfig` (this file will be gitignored — do NOT commit it)
- Modify: `.gitignore`

**Step 1: Create the committed template**

Create `Config.xcconfig.example` at the project root with:

```
// Copy this file to Config.xcconfig and fill in your server URL.
// Config.xcconfig is gitignored and must never be committed.

API_BASE_URL = http://YOUR_SERVER_IP:3000/api
```

**Step 2: Create your local Config.xcconfig**

Create `Config.xcconfig` at the project root with:

```
API_BASE_URL = http://192.168.178.169:3000/api
INFOPLIST_KEY_API_BASE_URL = $(API_BASE_URL)
```

`INFOPLIST_KEY_API_BASE_URL` causes Xcode to inject `API_BASE_URL` into the auto-generated Info.plist when building (because this project uses `GENERATE_INFOPLIST_FILE = YES`).

**Step 3: Update .gitignore**

Add `Config.xcconfig` to `.gitignore`. Final `.gitignore`:

```
.worktrees/
Config.xcconfig
```

**Step 4: Commit**

```bash
git add Config.xcconfig.example .gitignore
git commit -m "Add Config.xcconfig.example and gitignore for backend URL config"
```

Verify `Config.xcconfig` is NOT staged: `git status` should show it as untracked, not staged.

---

### Task 2: Wire Config.xcconfig into project.pbxproj

**Files:**
- Modify: `weekPlanWatch.xcodeproj/project.pbxproj`

The pbxproj must reference `Config.xcconfig` as the base build configuration for the Watch App target so Xcode picks up `INFOPLIST_KEY_API_BASE_URL` at build time.

**Step 1: Run the wiring script**

Run this Python script from the project root:

```python
import re, uuid

path = "weekPlanWatch.xcodeproj/project.pbxproj"
with open(path) as f:
    content = f.read()

# Generate a stable-looking ID for the xcconfig file reference
# Using a fixed ID so this script is idempotent
xcconfig_id = "3A000CF6C0FFEE0000000001"
group_id_to_use = None

# 1. Add PBXFileReference for Config.xcconfig (if not already present)
if xcconfig_id not in content:
    file_ref = f'\t\t{xcconfig_id} /* Config.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Config.xcconfig"; path = "Config.xcconfig"; sourceTree = "<group>"; }};\n'
    # Insert before "End PBXFileReference section"
    content = content.replace(
        "/* End PBXFileReference section */",
        file_ref + "/* End PBXFileReference section */"
    )
    print("Added PBXFileReference")
else:
    print("PBXFileReference already present, skipping")

# 2. Add to the main group (find the first PBXGroup that contains source files)
# Add to the group that already contains the xcodeproj reference
# Find the project's main group - it's the group listed under mainGroup
main_group_match = re.search(r'mainGroup = (\w+);', content)
if main_group_match:
    main_group_id = main_group_match.group(1)
    print(f"Main group ID: {main_group_id}")
    # Find that group and add our file ref to its children
    group_pattern = rf'({re.escape(main_group_id)} /\*[^*]*\*/ = \{{[^}}]*?children = \()(.*?)(\);)'
    group_match = re.search(group_pattern, content, re.DOTALL)
    if group_match and xcconfig_id not in group_match.group(0):
        new_children = group_match.group(2) + f'\t\t\t\t{xcconfig_id} /* Config.xcconfig */,\n'
        content = content[:group_match.start()] + group_match.group(1) + new_children + group_match.group(3) + content[group_match.end():]
        print("Added to main group children")
    else:
        print("Already in group or group not found")

# 3. Wire as baseConfigurationReference for Watch App Debug (3A1C9EE5) and Release (3A1C9EE6)
for config_id in ["3A1C9EE52F4AE71400CC4A34", "3A1C9EE62F4AE71400CC4A34"]:
    # Find the build configuration block and add baseConfigurationReference if missing
    block_pattern = rf'({re.escape(config_id)} /\*[^*]*\*/ = \{{)(.*?)(isa = XCBuildConfiguration;)'
    block_match = re.search(block_pattern, content, re.DOTALL)
    if block_match and "baseConfigurationReference" not in block_match.group(0):
        insertion = f'\n\t\t\tbaseConfigurationReference = {xcconfig_id} /* Config.xcconfig */;'
        content = content[:block_match.start(2)] + insertion + content[block_match.start(2):]
        print(f"Wired xcconfig for config {config_id}")
    else:
        print(f"Config {config_id}: already wired or not found")

with open(path, "w") as f:
    f.write(content)

print("Done. Open Xcode and verify the Watch App target shows Config.xcconfig under Build Settings.")
```

Save this as `scripts/wire_xcconfig.py` and run:

```bash
python3 scripts/wire_xcconfig.py
```

Expected output:
```
Added PBXFileReference
Main group ID: <some-id>
Added to main group children
Wired xcconfig for config 3A1C9EE52F4AE71400CC4A34
Wired xcconfig for config 3A1C9EE62F4AE71400CC4A34
Done. Open Xcode and verify the Watch App target shows Config.xcconfig under Build Settings.
```

**Step 2: Verify in Xcode**

Open `weekPlanWatch.xcodeproj` in Xcode. Select the project in the navigator → select the **weekPlanWatch Watch App** target → **Build Settings** tab → search for `API_BASE_URL`. It should appear with the value from your `Config.xcconfig`.

**Step 3: Commit**

```bash
git add weekPlanWatch.xcodeproj/project.pbxproj scripts/wire_xcconfig.py
git commit -m "Wire Config.xcconfig to Watch App build configurations"
```

---

### Task 3: Update WeekPlanService.swift to read URL from Bundle

**Files:**
- Modify: `weekPlanWatch Watch App/WeekPlanService.swift`

**Step 1: Write the failing test**

In `weekPlanWatch Watch AppTests/weekPlanWatch_Watch_AppTests.swift`, verify the test file exists and add a test for the URL resolution. The unit tests don't have Bundle access with real values, so we test the error path when the key is missing:

```swift
@Test func testLoadStateWhenServiceCannotReachServer() async {
    // This test verifies the service transitions to .error state
    // when the network call fails (no real server in tests)
    let service = WeekPlanService()
    await service.load()
    if case .error(_) = service.state {
        // expected - no server available in test environment
    } else if case .loading = service.state {
        Issue.record("Service should not stay in loading state")
    }
}
```

**Step 2: Run tests to establish baseline**

```bash
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" test 2>&1 | tail -20
```

Expected: tests pass (or show expected failures).

**Step 3: Replace hardcoded URL in WeekPlanService.swift**

Replace the top of `WeekPlanService.swift`. Current:

```swift
private let baseURL = "http://192.168.178.169:3000/api"
```

Replace with:

```swift
private let baseURL: String = {
    guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, !url.isEmpty else {
        fatalError("API_BASE_URL not set. Copy Config.xcconfig.example to Config.xcconfig and fill in your server URL.")
    }
    return url
}()
```

**Step 4: Run tests to verify no regressions**

```bash
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" test 2>&1 | tail -20
```

Expected: same result as baseline. The `fatalError` won't trigger in tests because `WeekPlanService.load()` is async — `baseURL` is only accessed when `load()` is called and the Bundle key is present.

**Step 5: Build to verify it compiles**

```bash
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" -configuration Debug build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`

**Step 6: Commit**

```bash
git add "weekPlanWatch Watch App/WeekPlanService.swift" "weekPlanWatch Watch AppTests/weekPlanWatch_Watch_AppTests.swift"
git commit -m "Read API_BASE_URL from Bundle.main.infoDictionary instead of hardcoded value"
```

---

### Task 4: Update README / contributor docs

**Files:**
- Modify: `CLAUDE.md` (if a README.md doesn't exist, update CLAUDE.md setup section)

**Step 1: Add setup instructions to CLAUDE.md**

In `CLAUDE.md`, add a **Setup** section after the Project Overview:

```markdown
## Setup

Before building, create your local config file:

```bash
cp Config.xcconfig.example Config.xcconfig
```

Edit `Config.xcconfig` and set `API_BASE_URL` to your backend server address.
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Add contributor setup instructions for Config.xcconfig"
```

---

### Task 5: Cleanup

**Step 1: Delete the wiring script (optional)**

The script was a one-time tool. You can keep it for future contributors or delete it:

```bash
git rm scripts/wire_xcconfig.py
git commit -m "Remove one-time xcconfig wiring script"
```

Or keep it with a comment at the top: `# One-time script to wire Config.xcconfig into project.pbxproj`

**Step 2: Final verification**

Run the app on a simulator or device. Confirm it loads today's recipe from your backend.

```bash
xcodebuild -project weekPlanWatch.xcodeproj -scheme "weekPlanWatch Watch App" -configuration Debug build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `** BUILD SUCCEEDED **` with no errors.
