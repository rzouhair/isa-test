#!/usr/bin/env python3
"""
Remove references to missing Swift files from an Xcode project.pbxproj.
Usage:
  python3 scripts/clean_pbxproj.py <project_root>
Scans the pbxproj for file references whose on-disk path no longer exists,
then strips: PBXBuildFile entries, PBXFileReference entries, and UUID mentions
in children/files arrays.
"""

import os
import re
import sys
from pathlib import Path

def main(root: Path) -> int:
    project_dir = root / "isaprep.xcodeproj"
    pbxproj = project_dir / "project.pbxproj"
    if not pbxproj.exists():
        print(f"pbxproj not found: {pbxproj}", file=sys.stderr)
        return 1

    text = pbxproj.read_text()

    # 1. Find every PBXFileReference with a `path = <something>.swift;` value
    #    and determine whether the file exists on disk (searching under isaprep/ recursively).
    fileref_pattern = re.compile(
        r'^\s*([0-9A-F]{24})\s*/\*[^*]*\*/\s*=\s*\{isa = PBXFileReference;[^}]*?path\s*=\s*"?([^";]+)"?;[^}]*?\};',
        re.MULTILINE,
    )

    # Build set of existing filenames under source roots (app + tests).
    source_roots = [root / "isaprep", root / "isaprepTests", root / "isaprepUITests"]
    existing_basenames = set()
    for src_root in source_roots:
        if not src_root.exists():
            continue
        for dirpath, _dirs, files in os.walk(src_root):
            for name in files:
                existing_basenames.add(name)

    missing_uuids = []  # list of (uuid, filename)
    for match in fileref_pattern.finditer(text):
        uuid, path_value = match.group(1), match.group(2)
        basename = os.path.basename(path_value)
        # Only prune Swift sources (other file types might legitimately live outside isaprep/).
        if basename.endswith(".swift") and basename not in existing_basenames:
            missing_uuids.append((uuid, basename))

    if not missing_uuids:
        print("No stale references.")
        return 0

    missing_uuid_set = {u for u, _ in missing_uuids}
    print(f"Pruning {len(missing_uuids)} stale file references:")
    for u, name in missing_uuids:
        print(f"  - {name} ({u})")

    # 2. Find all PBXBuildFile UUIDs that reference a missing file ref.
    buildfile_pattern = re.compile(
        r'^\s*([0-9A-F]{24})\s*/\*[^*]*\*/\s*=\s*\{isa = PBXBuildFile;\s*fileRef\s*=\s*([0-9A-F]{24})\s*/\*[^*]*\*/;[^}]*\};',
        re.MULTILINE,
    )
    missing_buildfile_uuids = set()
    for match in buildfile_pattern.finditer(text):
        bf_uuid, ref_uuid = match.group(1), match.group(2)
        if ref_uuid in missing_uuid_set:
            missing_buildfile_uuids.add(bf_uuid)

    all_uuids_to_strip = missing_uuid_set | missing_buildfile_uuids
    print(f"Also pruning {len(missing_buildfile_uuids)} PBXBuildFile entries.")

    # 3. Remove every line that contains any of those UUIDs.
    lines = text.splitlines(keepends=True)
    uuid_regex = re.compile(r'\b(' + '|'.join(sorted(all_uuids_to_strip)) + r')\b')
    kept = [ln for ln in lines if not uuid_regex.search(ln)]
    new_text = ''.join(kept)

    pbxproj.write_text(new_text)
    print(f"Wrote {pbxproj} ({len(lines)} -> {len(kept)} lines).")
    return 0


if __name__ == "__main__":
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    sys.exit(main(root))
