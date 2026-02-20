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
INPUT_FILE="${ROOT_DIR}/.sops/config.txt"
AGE_PUBLIC_KEY_FILE="${ROOT_DIR}/.sops/age.key"

# Validate that the configuration file exists
[[ -f "$INPUT_FILE" ]] || { echo -e "${RED}Error: $INPUT_FILE not found.${NC}"; exit 1; }

# Read the Age public key
AGE_PUBLIC_KEY=$(cat "$AGE_PUBLIC_KEY_FILE" 2>/dev/null)
[[ -z "$AGE_PUBLIC_KEY" ]] && { echo -e "${RED}Error: Age key empty or missing.${NC}"; exit 1; }

# Encrypt each file path listed in the configuration file
while IFS= read -r file_path || [[ -n "$file_path" ]]; do
    # Remove carriage returns, trim whitespace from file path and skip empty lines
    file_path=$(echo "$file_path" | tr -d '\r' | xargs)
    [[ -z "$file_path" ]] && continue

    # Validate full source file path
    FULL_SRC_PATH="$ROOT_DIR/$file_path"
    if [[ ! -f "$FULL_SRC_PATH" ]]; then
        echo -e "${RED}Warning: File $file_path not found. Skipping.${NC}"
        continue
    fi

    # Add .sops right before the file extension or at the end if the file has no extension
    encrypted_file="$ROOT_DIR/${file_path%.*}.sops${file_path##${file_path%.*}}"
    # Check if encrypted file already exists
    if [[ -f "$encrypted_file" ]]; then
        decrypted_temp=$(mktemp)
        # Decrypt existing file and compare with source file
        if sops --decrypt "$encrypted_file" >"$decrypted_temp" 2>/dev/null || \
           sops --decrypt --input-type binary --output-type binary "$encrypted_file" >"$decrypted_temp" 2>/dev/null; then
            if cmp -s "$FULL_SRC_PATH" "$decrypted_temp"; then
                [[ $VERBOSE == true ]] && echo -e "${GREEN}Skipping encryption of '${file_path}'.${NC}" || true
                continue
            fi
        fi
        rm -f "$decrypted_temp"
        echo -e "${RED}Changes detected in ${file_path}. Re-encrypting...${NC}"
    else
        echo -e "${RED}Encrypting: ${file_path}${NC}"
    fi

    # Attempt encryption with default settings first, fallback to binary if it fails
    if ! sops --encrypt --age "$AGE_PUBLIC_KEY" "$FULL_SRC_PATH" > "$encrypted_file" 2>/dev/null; then
        sops --encrypt --input-type binary --output-type binary --age "$AGE_PUBLIC_KEY" "$FULL_SRC_PATH" > "$encrypted_file"
    fi

done < "$INPUT_FILE"

echo -e "${GREEN}Encryption process completed.${NC}"
