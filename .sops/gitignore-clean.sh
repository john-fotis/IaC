#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITIGNORE="$ROOT_DIR/.gitignore"
START_MARKER="######## Auto-ignored SOPS Secrets ########"
END_MARKER="######## End of Auto-ignored SOPS Secrets ########"

if [ ! -f "$GITIGNORE" ]; then
    echo "Warning: .gitignore not found, nothing to clean."
    exit 0
fi

# Delete everything between markers, including the markers themselves
sed -i "/$START_MARKER/,/$END_MARKER/d" "$GITIGNORE"
sed -i -e ':a' -e 'N' -e '$!ba' -e "s/\n$START_MARKER/ $START_MARKER/" "$GITIGNORE"
sed -i "/$START_MARKER/,/$END_MARKER/d" "$GITIGNORE"
echo ".gitignore auto-ignored SOPS section has been removed."
