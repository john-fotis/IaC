#!/bin/bash

set -euo pipefail

usage() {
  printf "Usage: $0 [--bastion|-b <host>] [--dry-run|-d] [--verbose|-v]"
  exit 1
}

BASTION="hephaestus.integraceion.com"
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bastion|-b) [[ $# -ge 2 ]] || usage && BASTION="$2" && shift 2;;
    --dry-run|-d) DRY_RUN=true && shift;;
    --verbose|-v) VERBOSE=true && shift;;
    *) usage;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="/home/ansible/IaC/ansible"

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

BASTION_IP="$(dig +short "$BASTION" | head -n1)"
[[ -z "$BASTION_IP" ]] && printf "${RED}Failed to resolve IP for $BASTION${NC}" && exit 1

RSYNC_EXCLUDES=(
  "*.sh"
)
RSYNC_EXCLUDE_PARAMS=()
for ex in "${RSYNC_EXCLUDES[@]}"; do RSYNC_EXCLUDE_PARAMS+=(--exclude "$ex"); done

RSYNC_OPTS=(-az --perms --executability)
$DRY_RUN && RSYNC_OPTS+=(--dry-run)
$VERBOSE && RSYNC_OPTS+=(-v)

printf "${BLUE}Starting sync to '$BASTION'${NC}\n"

$DRY_RUN || ssh ansible@"$BASTION" "mkdir -p '$DEST_DIR'"
rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_PARAMS[@]}" "$SCRIPT_DIR/" ansible@"$BASTION:$DEST_DIR/"

printf "${GREEN}Sync completed successfully.${NC}"
