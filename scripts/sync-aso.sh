#!/usr/bin/env bash
# Sync ASO/<locale>/*.txt → fastlane/metadata/<fastlane-locale>/*.txt
# - Rename title.txt → name.txt (fastlane convention)
# - Strip `#`-prefixed alt lines and trailing blanks
# - Remap ASO locale codes → fastlane-accepted codes (ja-JP → ja, it-IT → it, ko-KR → ko)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/ASO"
DST="$ROOT/fastlane/metadata"

[[ -d "$SRC" ]] || { echo "missing $SRC"; exit 1; }
rm -rf "$DST"
mkdir -p "$DST"

# Map ASO locale → fastlane locale. Unlisted = pass-through.
map_locale() {
  case "$1" in
    ja-JP) echo "ja" ;;
    it-IT) echo "it" ;;
    ko-KR) echo "ko" ;;
    *) echo "$1" ;;
  esac
}

# Strip # alt lines (first '#' line ends content), trim trailing whitespace.
clean() {
  awk '/^#/{exit} {print}' "$1" | awk '{sub(/[[:space:]]+$/,""); print}' | awk 'BEGIN{blank=0} /^$/{blank++; next} {while(blank-->0) print ""; blank=0; print}'
}

for locale_dir in "$SRC"/*/; do
  src_locale="$(basename "$locale_dir")"
  dst_locale="$(map_locale "$src_locale")"
  out="$DST/$dst_locale"
  mkdir -p "$out"

  [[ -f "$locale_dir/title.txt" ]]    && clean "$locale_dir/title.txt"    > "$out/name.txt"
  [[ -f "$locale_dir/subtitle.txt" ]] && clean "$locale_dir/subtitle.txt" > "$out/subtitle.txt"

  for f in keywords.txt description.txt promotional_text.txt; do
    [[ -f "$locale_dir/$f" ]] && cp "$locale_dir/$f" "$out/$f"
  done

  if [[ "$src_locale" != "$dst_locale" ]]; then
    echo "synced: $src_locale → $dst_locale"
  else
    echo "synced: $src_locale"
  fi
done

echo "done → $DST"
