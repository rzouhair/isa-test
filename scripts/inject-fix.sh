#!/bin/bash

# Function to modify a single Swift file
modify_swift_file() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local tempfile="$filepath.tmp"

    # Check if the file should be processed
    if [[ $(grep -c ": View {" "$filepath") -eq 0 ]]; then
        echo "Skipping: $filename (No ': View {' found)"
        return
    fi

    # Create a temporary file for modifications
    cp "$filepath" "$tempfile"

    # 1. Add import Inject if needed
    if ! grep -q "import Inject" "$tempfile"; then
        sed -i '' -e '/^import SwiftUI/a\
import Inject' "$tempfile"
    fi

    # 2. Add @ObserveInjection var inject if needed
    if ! grep -q "@ObserveInjection var inject" "$tempfile"; then
        sed -i '' -e '/struct.*: View {/a\
    @ObserveInjection var inject' "$tempfile"
    fi

    # 3. Add .enableInjection() just before the closing brace of the body
    # Find the start of var body: some View {
    local body_start_line=$(grep -n "var body: some View {" "$tempfile" | cut -d ':' -f 1)

    if [[ -n "$body_start_line" ]]; then
        # Get the line number of the closing brace of the body
        local body_end_line=$(awk -v start="$body_start_line" '
            NR == start { count = 1 }
            NR > start {
                if ($0 ~ /{/) count++
                if ($0 ~ /}/) {
                    count--
                    if (count == 0) {
                        print NR
                        exit
                    }
                }
            }
        ' "$tempfile")

        if [[ -n "$body_end_line" ]]; then
            # Check if .enableInjection() is already present
            if ! grep -q ".enableInjection()" "$tempfile"; then
                # Insert .enableInjection() before the closing brace of the body
                sed -i '' -e "${body_end_line}i\\
        .enableInjection()" "$tempfile"
            fi
        fi
    fi

    # Check if modifications were made and overwrite the original file
    if ! cmp -s "$filepath" "$tempfile"; then
        mv "$tempfile" "$filepath"
        echo "Modified: $filename"
    else
        echo "No changes for: $filename"
    fi

    rm -f "$tempfile"
}

# Main script
find "$SRCROOT" -name "*.swift" -print0 | while IFS= read -r -d $'\0' filepath; do
    modify_swift_file "$filepath"
done

echo "Inject modification script completed."