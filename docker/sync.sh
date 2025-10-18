#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [prod|dmz] [--dry-run]" && exit 1
}

# Hosts per group
declare -A HOSTS=(
    [prod]="athena.integraceion.com"
    [dmz]="phobos.integraceion.com"
)

GROUP="${1:-}"
[[ -z "$GROUP" || -z "${HOSTS[$GROUP]:-}" ]] && usage

DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="~/docker"
TRAEFIK_DIR="services/traefik/config"
SOCKET_PROXY_DIR="services/socket-proxy"
ENV_FILE=".env.$GROUP"
COMPOSE_FILE="docker-compose-$GROUP.yaml"
TMP_SECRETS_DIR="/tmp/secrets"
TMP_TRAEFIK_DIR="/tmp/traefik"
TMP_SOCKET_PROXY_DIR="/tmp/socket-proxy"
TMP_ENV_FILE="/tmp/$ENV_FILE"
TMP_COMPOSE_FILE="/tmp/$COMPOSE_FILE"

# Rsync excludes
RSYNC_EXCLUDES=(
    'sync.sh'
    '*.log'
    'acme.json'
    '.git'
    '.gitignore'
    '.DS_Store'
    '*.swp'
    '*~'
    '*.sample*'
    '.yamllint'
    'README.md'
    '*.env*'
    'docker-compose*'
    'traefik/config/'
    'socket-proxy/'
    'secrets/'
)

RSYNC_EXCLUDE_PARAMS=()
for ex in "${RSYNC_EXCLUDES[@]}"; do
    RSYNC_EXCLUDE_PARAMS+=(--exclude "$ex")
done

RSYNC_OPTS=(-azv --perms --executability)
TEMP_RSYNC_OPTS=(-azv)
$DRY_RUN && RSYNC_OPTS+=(--dry-run) && TEMP_RSYNC_OPTS+=(--dry-run)

sync_and_deploy() {
    local label="$1" src="$2" tmp_dest="$3" move_cmd="$4"
    local GREEN='\033[1;32m' RED='\033[1;31m' NC='\033[0m'
    [[ -d "$src" && -z "$(ls -A "$src")" ]] && { echo -e "${RED}Skipping $label: empty dir.${NC}"; return; }
    echo -e "${GREEN}Uploading $label to $HOST:$tmp_dest${NC}"
    rsync "${TEMP_RSYNC_OPTS[@]}" $( [[ -d "$src" ]] && echo "$src/" || echo "$src" ) "$HOST:$tmp_dest"
    $DRY_RUN && echo -e "${GREEN}(Dry run) Skipping move for $label${NC}" || ssh "$HOST" "$move_cmd"
}

printf "Syncing '$GROUP' hosts...\n"

for HOST in ${HOSTS[$GROUP]}; do
    echo "Syncing $HOST..."

    # Sync general files
    rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_PARAMS[@]}" "$SCRIPT_DIR/" "$HOST:$DEST_DIR/"

    # Sync docker-compose.yaml
    sync_and_deploy "Docker Compose" \
        "$SCRIPT_DIR/$COMPOSE_FILE" "$TMP_COMPOSE_FILE" \
        "sudo mv $TMP_COMPOSE_FILE $DEST_DIR/docker-compose.yaml"

    # Sync secrets directory
    sync_and_deploy "secrets" \
        "$SCRIPT_DIR/secrets/$GROUP/" "$TMP_SECRETS_DIR/" \
        "sudo cp -a $TMP_SECRETS_DIR/. $DEST_DIR/secrets/ && rm -rf $TMP_SECRETS_DIR"

    # Sync .env file if it exists
    if [[ -f "$SCRIPT_DIR/$ENV_FILE" ]]; then
        sync_and_deploy "env file" \
            "$SCRIPT_DIR/$ENV_FILE" "$TMP_ENV_FILE" \
            "sudo mv $TMP_ENV_FILE $DEST_DIR/.env"
    else
        echo -e "\033[1;31mWarning: $SCRIPT_DIR/$ENV_FILE not found, skipping environment file sync.\033[0m"
    fi

    # Sync the common traefik config folder
    sync_and_deploy "traefik common config" \
        "$SCRIPT_DIR/$TRAEFIK_DIR/common/" "$TMP_TRAEFIK_DIR-common/" \
        "sudo cp -a $TMP_TRAEFIK_DIR-common/. $DEST_DIR/$TRAEFIK_DIR && rm -rf $TMP_TRAEFIK_DIR-common"

    # Sync traefik config for the specific group
    sync_and_deploy "traefik config" \
        "$SCRIPT_DIR/$TRAEFIK_DIR/$GROUP/" "$TMP_TRAEFIK_DIR/" \
        "sudo cp -a $TMP_TRAEFIK_DIR/. $DEST_DIR/$TRAEFIK_DIR && rm -rf $TMP_TRAEFIK_DIR"

    # Sync socket proxy config
    sync_and_deploy "socket proxy config" \
        "$SCRIPT_DIR/$SOCKET_PROXY_DIR/$GROUP/" "$TMP_SOCKET_PROXY_DIR/" \
        "sudo cp -a $TMP_SOCKET_PROXY_DIR/. $DEST_DIR/$SOCKET_PROXY_DIR && rm -rf $TMP_SOCKET_PROXY_DIR"

    echo "---"
done

echo -e "\033[1;32mSync completed.\033[0m"
