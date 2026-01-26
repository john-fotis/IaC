#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="$ROOT_DIR/.sops/config.txt"

# Preparation
cd "$ROOT_DIR"
> "$OUTPUT_FILE"

# Find all files that should be encrypted, excluding templates and existing .sops files
advanced_find() {
    find "$@" ! -path "*template*/*" ! -name "*.sops" >> "$OUTPUT_FILE"
}

# .env files (except .env.sample)
advanced_find docker/ -maxdepth 1 -type f -name ".env*" ! -name ".env.sample"

# Docker secrets folder
advanced_find docker/secrets -type f

# All traefik.yaml files under docker/services/traefik
advanced_find docker/services/traefik -type f -name "traefik.yaml"

# All inventory files in ansible
advanced_find ansible/inventories -type f

# All ansible.cfg files
advanced_find ansible -type f -name "ansible.cfg"

# All .conf files (except ones containing 'sample')
advanced_find . -type f -name "*.conf" ! -iname "*sample*"

# Deduplicate and sort
sort -u "$OUTPUT_FILE" -o "$OUTPUT_FILE"

# Cleanup
sed -i 's|^\./||' "$OUTPUT_FILE"
sed -i '/\.sops$/d' "$OUTPUT_FILE"

echo "Secrets located and filtered in $OUTPUT_FILE"