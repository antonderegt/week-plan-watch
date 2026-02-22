# One-time script used to wire Config.xcconfig into weekPlanWatch.xcodeproj/project.pbxproj.
# Already applied. Safe to re-run (idempotent) if you need to re-wire a fresh project file.
import re

path = "weekPlanWatch.xcodeproj/project.pbxproj"
with open(path) as f:
    content = f.read()

# Fixed ID so this script is idempotent
xcconfig_id = "3A000CF6C0FFEE0000000001"

# 1. Add PBXFileReference for Config.xcconfig (if not already present)
if xcconfig_id not in content:
    file_ref = f'\t\t{xcconfig_id} /* Config.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Config.xcconfig"; path = "Config.xcconfig"; sourceTree = "<group>"; }};\n'
    content = content.replace(
        "/* End PBXFileReference section */",
        file_ref + "/* End PBXFileReference section */"
    )
    print("Added PBXFileReference")
else:
    print("PBXFileReference already present, skipping")

# 2. Add to the main group
main_group_match = re.search(r'mainGroup = (\w+);', content)
if main_group_match:
    main_group_id = main_group_match.group(1)
    print(f"Main group ID: {main_group_id}")
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

print("Done.")
