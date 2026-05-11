#!/usr/bin/env python3
"""Recreate the PBXFrameworksBuildPhase + product PBXBuildFile entries for the
main `isaprep` target. The orphan-cleanup pass during the ISA reskin nuked
them because SPM-product PBXBuildFile rows use `productRef` instead of
`fileRef` and tripped the "no fileRef" check.
"""

import os
import sys

from pbxproj import XcodeProject
from pbxproj.pbxsections import PBXBuildFile, PBXFrameworksBuildPhase

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, "isaprep.xcodeproj", "project.pbxproj")

# (Display name, XCSwiftPackageProductDependency id)
PRODUCTS = [
    ("RevenueCat",   "CEE986A62DAADED70016D3FC"),
    ("RevenueCatUI", "CEE986AA2DAADED70016D3FC"),
    ("Inject",       "CE8DF48C2DAC248E0052EFDD"),
    ("Sentry",       "26124F682F881D210043C162"),
    ("PostHog",      "26124F722F881DA30043C162"),
    ("GRDB",         "5A8E01D847F2912E08ABF8FC"),
]

TARGET_NAMES = ["isaprep"]


def find_target(project, name):
    for t in project.objects.get_objects_in_section("PBXNativeTarget"):
        if t.name == name:
            return t
    return None


def ensure_frameworks_phase(project, target):
    for ph_id in target.buildPhases:
        ph = project.objects[ph_id]
        if ph.isa == "PBXFrameworksBuildPhase":
            return ph
    # Create one.
    ph = PBXFrameworksBuildPhase.create(files=[])
    project.objects[ph.get_id()] = ph
    target.buildPhases.append(ph.get_id())
    return ph


def ensure_buildfile(project, phase, product_id, product_name):
    for bf_id in phase.files:
        bf = project.objects.get(bf_id, None)
        if bf and getattr(bf, "productRef", None) == product_id:
            return bf_id
    product_obj = project.objects[product_id]
    bf = PBXBuildFile.create(file_ref=product_obj, is_product=True)
    project.objects[bf.get_id()] = bf
    phase.files.append(bf.get_id())
    return bf.get_id()


def main() -> int:
    project = XcodeProject.load(PBX)
    for tname in TARGET_NAMES:
        target = find_target(project, tname)
        if target is None:
            print(f"  (skip) no target {tname}")
            continue
        phase = ensure_frameworks_phase(project, target)
        for pname, pid in PRODUCTS:
            ensure_buildfile(project, phase, pid, pname)
            print(f"  linked {pname} ({pid}) to {tname}")
    project.save()
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
