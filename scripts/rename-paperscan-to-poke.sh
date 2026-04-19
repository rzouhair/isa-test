#!/usr/bin/env bash
# Re-applies the PaperScan → Poke rename across the project by invoking
# scripts/rename.swift for both casings. Safe to re-run; no-op when nothing
# matches.
#
# Usage:
#   ./scripts/rename-paperscan-to-poke.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ Renaming PaperScan → Poke"
swift scripts/rename.swift PaperScan Poke

echo "→ Renaming paperscan → poke"
swift scripts/rename.swift paperscan poke || true

echo "→ Refreshing graphify cache (optional)"
if command -v graphify >/dev/null 2>&1; then
    graphify update .
else
    echo "   graphify not installed; skipping"
fi

echo "Done."
