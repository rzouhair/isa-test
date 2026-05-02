#!/usr/bin/env bash
# Wrapper that runs scripts/project_add.rb with user-gem load paths.
# macOS system Ruby (2.6) does not auto-pick up ~/.gem — we pass -I explicitly.
set -euo pipefail

GEM_ROOT="${HOME}/.gem/ruby/2.6.0/gems"
LIBS=(
  "${GEM_ROOT}/xcodeproj-1.27.0/lib"
  "${GEM_ROOT}/nanaimo-0.4.0/lib"
  "${GEM_ROOT}/atomos-0.1.3/lib"
  "${GEM_ROOT}/claide-1.1.0/lib"
  "${GEM_ROOT}/colored2-3.1.2/lib"
)

INCLUDES=()
for dir in "${LIBS[@]}"; do
  [[ -d "$dir" ]] || { echo "Missing gem dir: $dir — run: gem install --user-install xcodeproj" >&2; exit 1; }
  INCLUDES+=(-I "$dir")
done

exec ruby "${INCLUDES[@]}" "$(dirname "$0")/project_add.rb" "$@"
