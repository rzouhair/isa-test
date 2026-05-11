#!/usr/bin/env python3
"""Pbxproj surgery for the ISA reskin.

* Removes file refs / build files for deleted CDL features.
* Adds new ISA flashcard model + feature files to the main target.

Run idempotently from repo root.
"""

import os
import sys

from pbxproj import XcodeProject
from pbxproj.pbxextensions import TreeType, FileOptions

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, "isaprep.xcodeproj", "project.pbxproj")
TARGET_ID = "CE46EF9E2D57C17E004CFB49"  # isaprep main target

REMOVE = [
    "StateSelectView.swift",
    "HandbookView.swift",
    "CheatSheetListView.swift",
    "CheatSheetDetailView.swift",
    "EditStateView.swift",
    "OnboardingStateStepView.swift",
    "handbooks.json",
]

ADD = [
    "isaprep/Domain/Models/FlashcardReview.swift",
    "isaprep/Domain/Models/BookmarkedFlashcard.swift",
    "isaprep/Features/Flashcards/FlashcardsLibraryView.swift",
    "isaprep/Features/Flashcards/FlashcardsLibraryViewModel.swift",
    "isaprep/Features/Flashcards/FlashcardSessionView.swift",
    "isaprep/Features/Flashcards/FlashcardSessionViewModel.swift",
    "isaprep/Features/Flashcards/FlashcardBookmarksView.swift",
]


def find_target_obj(project, target_id):
    for t in project.objects.get_objects_in_section("PBXNativeTarget"):
        if t.get_id() == target_id:
            return t
    return None


def cleanup_orphan_buildfiles(project):
    """Remove PBXBuildFile entries that point at no fileRef and any whose
    fileRef no longer exists."""
    bf_objects = list(project.objects.get_objects_in_section("PBXBuildFile"))
    to_remove = []
    for bf in bf_objects:
        ref = getattr(bf, "fileRef", None)
        bf_id = bf.get_id()
        if ref is None:
            to_remove.append(bf_id)
            continue
        if project.get_object(ref) is None:
            to_remove.append(bf_id)
    for bf_id in to_remove:
        del project.objects[bf_id]
        for phase_section in ("PBXSourcesBuildPhase", "PBXResourcesBuildPhase",
                              "PBXFrameworksBuildPhase", "PBXHeadersBuildPhase"):
            for phase in project.objects.get_objects_in_section(phase_section):
                if hasattr(phase, "files") and bf_id in phase.files:
                    phase.files.remove(bf_id)
    return len(to_remove)


def add_source_file(project, abs_path, rel_to_root, target_id):
    """Manually wire a source file: PBXFileReference + PBXBuildFile + Sources phase."""
    from pbxproj.pbxsections import PBXFileReference, PBXBuildFile

    name = os.path.basename(abs_path)
    # Already present?
    for f in project.objects.get_objects_in_section("PBXFileReference"):
        if getattr(f, "name", None) == name or getattr(f, "path", None) == rel_to_root:
            return None  # already exists

    file_ref = PBXFileReference.create(
        path=rel_to_root,
        tree=TreeType.SOURCE_ROOT,
    )
    file_ref.name = name
    project.objects[file_ref.get_id()] = file_ref

    # Drop into the main group so it shows up in the navigator.
    main_group_id = project.objects[project.rootObject].mainGroup
    project.objects[main_group_id].children.append(file_ref.get_id())

    build_file = PBXBuildFile.create(file_ref=file_ref)
    project.objects[build_file.get_id()] = build_file

    # Find Sources phase for the target.
    target = find_target_obj(project, target_id)
    if target is None:
        raise RuntimeError(f"target {target_id} not found")
    for phase_id in target.buildPhases:
        phase = project.objects[phase_id]
        if phase.isa == "PBXSourcesBuildPhase":
            phase.files.append(build_file.get_id())
            return file_ref.get_id()
    raise RuntimeError("no PBXSourcesBuildPhase on target")


def main() -> int:
    project = XcodeProject.load(PBX)

    for fname in REMOVE:
        results = project.get_files_by_name(fname)
        if not results:
            print(f"  (skip) no ref for {fname}")
            continue
        for f in results:
            project.remove_file_by_id(f.get_id())
            print(f"  removed {fname}")

    n = cleanup_orphan_buildfiles(project)
    if n:
        print(f"  cleaned {n} orphan build files")

    for path in ADD:
        absolute = os.path.join(ROOT, path)
        if not os.path.exists(absolute):
            print(f"  (skip add) missing {path}")
            continue
        existing = project.get_files_by_name(os.path.basename(path))
        if existing:
            print(f"  (skip add) already in project: {path}")
            continue
        added = add_source_file(project, absolute, path, TARGET_ID)
        print(f"  added {path} -> {added}")

    project.save()
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
