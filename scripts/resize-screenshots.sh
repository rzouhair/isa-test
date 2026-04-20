#!/usr/bin/env bash
# Resize PNG/JPG images to App Store Connect dimensions.
# Uses macOS built-in `sips` - no install needed.
#
# Usage:
#   ./scripts/resize-screenshots.sh <input_dir> [preset]
#   ./scripts/resize-screenshots.sh <input_dir> <WIDTHxHEIGHT>
#
# Presets:
#   6.9    -> 1320x2868  (iPhone 16 Pro Max - current required)
#   6.7    -> 1290x2796  (iPhone 15 Pro Max etc)
#   6.5    -> 1284x2778  (iPhone 11 Pro Max - App Store "Recommended")
#   5.5    -> 1242x2208  (iPhone 8 Plus legacy)
#   ipad13 -> 2064x2752  (iPad Pro 13")
#   ipad12 -> 2048x2732  (iPad Pro 12.9")

set -eo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <input_dir> [preset|WIDTHxHEIGHT]"
  echo "       presets: 6.9 6.7 6.5 5.5 ipad13 ipad12"
  exit 1
fi

IN="$1"
PRESET="${2:-6.5}"

W=""
H=""

case "$PRESET" in
  6.9)    W=1320; H=2868 ;;
  6.7)    W=1290; H=2796 ;;
  6.5)    W=1284; H=2778 ;;
  5.5)    W=1242; H=2208 ;;
  ipad13) W=2064; H=2752 ;;
  ipad12) W=2048; H=2732 ;;
  *x*)    W="${PRESET%x*}"; H="${PRESET#*x}" ;;
  *)      echo "unknown preset: $PRESET"; exit 1 ;;
esac

if [ -z "$W" ] || [ -z "$H" ]; then
  echo "could not determine W/H from: $PRESET"
  exit 1
fi

if [ ! -d "$IN" ]; then
  echo "not a directory: $IN"
  exit 1
fi

OUT="${IN%/}_resized"
mkdir -p "$OUT"

count=0
while IFS= read -r -d '' f; do
  rel="${f#$IN/}"
  dst="$OUT/$rel"
  mkdir -p "$(dirname "$dst")"
  sips -z "$H" "$W" "$f" --out "$dst" > /dev/null
  count=$((count + 1))
  echo "resized (${W}x${H}): $rel"
done < <(find "$IN" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0)

echo ""
echo "done -> $OUT ($count files, ${W}x${H})"
