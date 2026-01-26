#!/bin/bash

# Define ANSI color codes for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Set ROOT_DIR as the parent directory of .sops folder
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Cleanup function to remove temporary files on exit
cleanup() {
    [ -f "$decrypted_temp" ] && rm "$decrypted_temp"
}
trap cleanup EXIT

# Find all .sops files and decrypt them
find "$ROOT_DIR" -type f -name "*.sops" | while IFS= read -r file; do
    # Convert absolute paths to relative paths and prepare decrypted filenames
    relative_file="${file#$ROOT_DIR/}"
    decrypted_file="${relative_file/.sops/}"

    if [ -f "$ROOT_DIR/$decrypted_file" ]; then
        # File exists, decrypt and compare
        decrypted_temp=$(mktemp) || { echo "Failed to create temporary file"; exit 1; }
        if ! sops --decrypt "$file" >"$decrypted_temp"; then
            echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
            continue
        fi
        # Compare the decrypted content with the existing file
        if cmp -s "$ROOT_DIR/$decrypted_file" "$decrypted_temp"; then
            echo -e "${GREEN}No changes detected in $relative_file. Skipping decryption...${NC}"
        else
            # Replace existing file with decrypted content
            mv "$decrypted_temp" "$ROOT_DIR/$decrypted_file"
            echo -e "${RED}File $decrypted_file replaced with the decrypted content${NC}"
        fi
    else
        # File doesn't exist, decrypt and create it
        echo -e "${RED}Decrypting file: $relative_file${NC}"
        if ! sops --decrypt "$file" >"$ROOT_DIR/$decrypted_file"; then
            echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
        fi
    fi
done
