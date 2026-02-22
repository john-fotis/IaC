#!/bin/bash

# Define ANSI color codes for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
VERBOSE=false
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=true ;;
    esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="$ROOT_DIR/.sops/config.txt"
AGE_PUBLIC_KEY_FILE="$ROOT_DIR/.sops/age.key"

# Validate that the configuration file exists
[[ -f "$INPUT_FILE" ]] || { echo -e "${RED}Error: $INPUT_FILE not found.${NC}"; exit 1; }

# Read the Age public key
AGE_PUBLIC_KEY=$(<"$AGE_PUBLIC_KEY_FILE")
[[ -n "$AGE_PUBLIC_KEY" ]] || { echo -e "${RED}Error: Age key empty or missing.${NC}"; exit 1; }

# Encrypt each file path listed in the configuration file
while IFS= read -r file_path || [[ -n "$file_path" ]]; do
    # Remove carriage returns, trim whitespace from file path and skip empty lines
    file_path=$(echo "$file_path" | tr -d '\r' | xargs)
    [[ -z "$file_path" ]] && continue
    # Validate full source file path
    src="$ROOT_DIR/$file_path"
    [[ -f "$src" ]] || { echo -e "${RED}Warning: '$file_path' not found.${NC}"; continue; }
    # Add .sops right before the file extension or at the end if the file has no extension
    enc="$ROOT_DIR/${file_path%.*}.sops${file_path##${file_path%.*}}"
    # Check if encrypted file already exists
    if [[ -f "$enc" ]]; then
        tmp=$(mktemp)
        if ! sops --decrypt "$enc" >"$tmp" 2>/dev/null; then
        # Decrypt existing file and compare with source file
            sops --decrypt --input-type binary --output-type binary "$enc" >"$tmp" 2>/dev/null || {
                echo -e "${RED}Failed to decrypt existing encrypted file: $file_path${NC}"
                rm -f "$tmp" && continue
            }
        fi
        if cmp -s "$src" "$tmp"; then
            $VERBOSE && echo -e "${GREEN}Skipping encryption of '$file_path'${NC}"
            rm -f "$tmp" && continue
        fi
        rm -f "$tmp"
        echo -e "${RED}Re-encrypting '$file_path'${NC}"
    else
        echo -e "${RED}Encrypting: '$file_path'${NC}"
    fi
    # Attempt encryption with default settings first, fallback to binary if it fails
    sops --encrypt --age "$AGE_PUBLIC_KEY" "$src" >"$enc" 2>/dev/null || \
    sops --encrypt --input-type binary --output-type binary --age "$AGE_PUBLIC_KEY" "$src" >"$enc"
done < "$INPUT_FILE"

$VERBOSE && echo -e "${GREEN}Encryption process completed.${NC}" || true
