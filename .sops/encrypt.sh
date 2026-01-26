#!/bin/bash

# Define ANSI color codes for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

    # Validate full source file path and define encrypted file path
    FULL_SRC_PATH="$ROOT_DIR/$file_path"
    if [[ ! -f "$FULL_SRC_PATH" ]]; then
        echo -e "${RED}Warning: File $file_path not found. Skipping.${NC}"
        continue
    fi
    ENCRYPTED_FILE="${FULL_SRC_PATH}.sops"

    # Check if encrypted file already exists
    if [[ -f "$ENCRYPTED_FILE" ]]; then
        # Create temporary file for decrypted comparison
        decrypted_temp=$(mktemp)
        # Decrypt existing file in binary mode and compare with source file
        if sops --decrypt --input-type binary --output-type binary "$ENCRYPTED_FILE" >"$decrypted_temp" 2>/dev/null; then
            if cmp -s "$FULL_SRC_PATH" "$decrypted_temp"; then
                echo -e "${GREEN}No changes detected in ${file_path}. Skipping...${NC}"
                rm "$decrypted_temp"
                continue
            fi
        fi
        rm -f "$decrypted_temp"
        echo -e "${RED}Changes detected in ${file_path}. Re-encrypting...${NC}"
    else
        echo -e "${RED}Encrypting: ${file_path}${NC}"
    fi

    # Encrypt source file in binary mode to preserve formatting and avoid parsing errors
    sops --encrypt --age "$AGE_PUBLIC_KEY" --input-type binary --output-type binary "$FULL_SRC_PATH" > "$ENCRYPTED_FILE"

done < "$INPUT_FILE"

echo -e "${GREEN}Encryption process completed.${NC}"
