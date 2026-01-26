#!/usr/bin/env bash
set -euo pipefail

# Set ROOT_DIR as the parent directory of .sops folder
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.sops/config.txt"
START_MARKER="######## Auto-ignored SOPS Secrets ########"
END_MARKER="######## End of Auto-ignored SOPS Secrets ########"
TEMP_FILE=$(mktemp)

# Validate that the configuration file exists
[[ ! -f "$CONFIG_FILE" ]] && echo "Error: $CONFIG_FILE not found." && exit 1 || true

# Add markers to .gitignore if they don't already exist
grep -Fxq "$START_MARKER" "$ROOT_DIR/.gitignore" || printf "$START_MARKER\n" >> "$ROOT_DIR/.gitignore"
grep -Fxq "$END_MARKER" "$ROOT_DIR/.gitignore" || printf "$END_MARKER\n" >> "$ROOT_DIR/.gitignore"

# Read config file and add entries and their .sops variants to temp file
while IFS= read -r file; do
    echo "$file" >> "$TEMP_FILE"
    echo "!$file.sops" >> "$TEMP_FILE"
done < "$CONFIG_FILE"

# Sort and deduplicate entries
sort -u "$TEMP_FILE" -o "$TEMP_FILE"

# Remove existing auto-ignored content between markers
sed -i "/$START_MARKER/,/$END_MARKER/{//!d}" "$ROOT_DIR/.gitignore"

# Insert sorted entries after START_MARKER
sed -i "/$START_MARKER/r $TEMP_FILE" "$ROOT_DIR/.gitignore"

# Clean up temporary file
rm "$TEMP_FILE"

# Remove tracked files from git cache for each config entry
xargs -a "$CONFIG_FILE" -I {} bash -c 'git ls-files --error-unmatch "$1" >/dev/null 2>&1 && git rm --cached "$1" || true' _

# Stage the updated .gitignore
git add "$ROOT_DIR/.gitignore"
echo ".gitignore has been updated and staged."