#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=false
for arg in "$@"; do
    case "$arg" in
        -v|--verbose)
            VERBOSE=true
        ;;
    esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Find all .sops files except .sops.yaml
while IFS= read -r file; do
    relative_file="${file#$ROOT_DIR/}"
    decrypted_file="${relative_file/.sops/}"
    decrypted_path="$ROOT_DIR/$decrypted_file"
    if [[ -f "$decrypted_path" ]]; then
        decrypted_temp="$(mktemp)"
        if ! sops --decrypt "$file" >"$decrypted_temp" 2>/dev/null; then
            if ! sops --decrypt --input-type binary --output-type binary "$file" >"$decrypted_temp" 2>/dev/null; then
                echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
                rm -f "$decrypted_temp"
                continue
            fi
        fi
        if cmp -s "$decrypted_path" "$decrypted_temp"; then
            $VERBOSE && echo -e "${GREEN}Skipping decryption of '$relative_file'${NC}"
            rm -f "$decrypted_temp"
        else
            mv "$decrypted_temp" "$decrypted_path"
            echo -e "${RED}Decrypted '$decrypted_file'${NC}"
        fi
    else
        echo -e "${RED}Decrypting file: $relative_file${NC}"
        if ! sops --decrypt "$file" >"$decrypted_path" 2>/dev/null; then
            if ! sops --decrypt --input-type binary --output-type binary "$file" >"$decrypted_path" 2>/dev/null; then
                echo -e "${RED}Failed to decrypt file: $relative_file${NC}"
            fi
        fi
    fi
done < <(find "$ROOT_DIR" -type f \( -name "*.sops" -o -name "*.sops.*" \) ! -name ".sops.yaml")

$VERBOSE && echo -e "${GREEN}Decryption process completed.${NC}" || true
