#!/bin/bash

# Define ANSI color codes for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
VERBOSE=false
for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE=true
            shift
        ;;
    esac
done

# Set ROOT_DIR as the parent directory of .sops folder
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Cleanup function to remove temporary files on exit
cleanup() {
    [ -f "$decrypted_temp" ] && rm "$decrypted_temp"
}
trap cleanup EXIT

# Find all .sops files and decrypt them (excluding ".sops.yaml")
find "$ROOT_DIR" -type f \( -name "*.sops" -o -name "*.sops.*" \) ! -path "$ROOT_DIR/.sops.yaml" | while IFS= read -r file; do    # Convert absolute paths to relative paths and prepare decrypted filenames
    relative_file="${file#$ROOT_DIR/}"
    decrypted_file="${relative_file/.sops/}"

    if [ -f "$ROOT_DIR/$decrypted_file" ]; then
        # File exists, decrypt and compare
        decrypted_temp=$(mktemp) || { echo "Failed to create temporary file"; exit 1; }
        if ! sops --decrypt "$file" >"$decrypted_temp" 2>/dev/null; then
            if ! sops --decrypt --input-type binary --output-type binary "$file" >"$decrypted_temp" 2>/dev/null; then
                echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
                continue
            fi
        fi
        # Compare the decrypted content with the existing file
        if cmp -s "$ROOT_DIR/$decrypted_file" "$decrypted_temp"; then
            [[ $VERBOSE == true ]] && echo -e "${GREEN}Skipping decryption of '$relative_file.'${NC}" || true
        else
            # Replace existing file with decrypted content
            mv "$decrypted_temp" "$ROOT_DIR/$decrypted_file"
            echo -e "${RED}File $decrypted_file replaced with the decrypted content${NC}"
        fi
    else
        # File doesn't exist, decrypt and create it
        echo -e "${RED}Decrypting file: $relative_file${NC}"
        if ! sops --decrypt "$file" >"$ROOT_DIR/$decrypted_file" 2>/dev/null; then
            if ! sops --decrypt --input-type binary --output-type binary "$file" >"$ROOT_DIR/$decrypted_file"; then
                echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
            fi
        fi
    fi
done

echo -e "${GREEN}Encryption process completed.${NC}"
