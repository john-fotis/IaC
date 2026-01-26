#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [prod|dmz] [--dry-run] [--verbose|-v]" && exit 1
}

# Argument parsing
DRY_RUN=false
VERBOSE=false
for arg in "$@"; do
    case $arg in
        prod|dmz) GROUP=$arg ;;
        --dry-run) DRY_RUN=true ;;
        --verbose|-v) VERBOSE=true ;;
        *) usage ;;
    esac
done

# Hosts per group
declare -A HOSTS=(
    [prod]="athena.integraceion.com"
    [dmz]="phobos.integraceion.com"
)

GROUP="${1:-}"
[[ -z "$GROUP" || -z "${HOSTS[$GROUP]:-}" ]] && usage

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
RED='\033[1;31m'; GREEN='\033[1;32m'; BLUE='\033[1;34m'; GREY='\033[1;30m'; NC='\033[0m'

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
for ex in "${RSYNC_EXCLUDES[@]}"; do RSYNC_EXCLUDE_PARAMS+=(--exclude "$ex"); done

RSYNC_OPTS=(-az --perms --executability)
TEMP_RSYNC_OPTS=(-az)
$DRY_RUN && RSYNC_OPTS+=(--dry-run) && TEMP_RSYNC_OPTS+=(--dry-run)
$VERBOSE && RSYNC_OPTS+=(-v) && TEMP_RSYNC_OPTS+=(-v)

sync_and_deploy() {
    local label="$1" src="$2" tmp_dest="$3" move_cmd="$4"
    [[ -d "$src" && -z "$(ls -A "$src")" ]] && { echo -e "${RED}Skipping $label: empty dir.${NC}"; return; }
    echo -e "${GREEN}Uploading $label to $HOST:$tmp_dest${NC}"
    rsync "${TEMP_RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_PARAMS[@]}" $( [[ -d "$src" ]] && echo "$src/" || echo "$src" ) "$HOST:$tmp_dest"
    $DRY_RUN && echo -e "${GREEN}(Dry run) Skipping move for $label${NC}" || ssh "$HOST" "$move_cmd"
}

# Check if service belongs to the group
profile_matches_group() {
    local file="$1"
    grep -qiE "profiles:.*($GROUP|\[.*$GROUP.*\])" "$file" || \
    grep -A 15 "profiles:" "$file" | grep -qiE -- "-[[:space:]]+['\"]?$GROUP['\"]?"
}

# Check if service is to be excluded from rsync
service_is_excluded() { local base="$1" && [[ " ${RSYNC_EXCLUDES[*]%/} " =~ " $base " ]] }

printf "${BLUE}Starting sync for group: '$GROUP'${NC}\n"

for HOST in ${HOSTS[$GROUP]}; do
    echo "==================================================="
    echo -e "${BLUE}Syncing Host: $HOST${NC}"
    echo "==================================================="

    # Profile-based Sync of general Services
    printf "${BLUE}Transferring services matching profile ${GREY}${GROUP}${BLUE}...${NC}\n"
    mapfile -t SERVICES < <(find "$SCRIPT_DIR/services" -name "compose.yaml" -type f)
    for svc in "${SERVICES[@]}"; do
        rel="${svc#$SCRIPT_DIR/services/}"
        dir=$(dirname "$rel")
        service_is_excluded "${dir%%/*}" && continue
        if profile_matches_group "$svc"; then
            echo -e "${GREEN}[OK] Service: $dir${NC}"
            $DRY_RUN || ssh -n "$HOST" "mkdir -p $DEST_DIR/services/$dir"
            rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_PARAMS[@]}" \
                "$(dirname "$svc")/" "$HOST:$DEST_DIR/services/$dir/"
        elif ! grep -qi "profiles:" "$svc"; then
            echo -e "${RED}[KO] Service: $dir (No profile key)${NC}"
        fi
    done

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
        echo -e "${RED}Warning: $SCRIPT_DIR/$ENV_FILE not found, skipping environment file sync.${NC}"
    fi

    # Sync Traefik Common Config
    sync_and_deploy "Traefik Common Config" \
        "$SCRIPT_DIR/$TRAEFIK_DIR/common/" "$TMP_TRAEFIK_DIR-common/" \
        "sudo cp -a $TMP_TRAEFIK_DIR-common/. $DEST_DIR/$TRAEFIK_DIR && rm -rf $TMP_TRAEFIK_DIR-common"

    # Sync Environment-Specific Traefik config
    sync_and_deploy "Traefik Config" \
        "$SCRIPT_DIR/$TRAEFIK_DIR/$GROUP/" "$TMP_TRAEFIK_DIR/" \
        "sudo cp -a $TMP_TRAEFIK_DIR/. $DEST_DIR/$TRAEFIK_DIR && rm -rf $TMP_TRAEFIK_DIR"

    # Sync Environment-Specific Socket Proxy config
    sync_and_deploy "Socket Proxy Config" \
        "$SCRIPT_DIR/$SOCKET_PROXY_DIR/$GROUP/" "$TMP_SOCKET_PROXY_DIR/" \
        "sudo cp -a $TMP_SOCKET_PROXY_DIR/. $DEST_DIR/$SOCKET_PROXY_DIR && rm -rf $TMP_SOCKET_PROXY_DIR"
done

echo -e "\n${GREEN}Sync completed successfully for $GROUP.${NC}"
