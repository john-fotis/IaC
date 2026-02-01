#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [prod|dmz] [--dry-run|-d] [--verbose|-v]" && exit 1
}

DRY_RUN=false
VERBOSE=false
for arg in "$@"; do
    case $arg in
        prod|dmz) GROUP=$arg ;;
        --dry-run|-d) DRY_RUN=true ;;
        --verbose|-v) VERBOSE=true ;;
        *) usage ;;
    esac
done

declare -A HOSTS=(
    [prod]="athena.integraceion.com"
    [dmz]="phobos.integraceion.com"
)

GROUP="${1:-}"
[[ -z "$GROUP" || -z "${HOSTS[$GROUP]:-}" ]] && usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/docker"
TMP_DIR="/tmp/$GROUP"
TRAEFIK_DIR="services/traefik/config"
SOCKET_PROXY_DIR="services/socket-proxy"
ENV_FILE=".env.$GROUP"
COMPOSE_FILE="docker-compose-$GROUP.yaml"
RED='\033[1;31m'; GREEN='\033[1;32m'; BLUE='\033[1;34m'; NC='\033[0m'

# Prepare rsync parameters
RSYNC_EXCLUDES=(
    'secrets/'
    'socket-proxy/'
    'traefik/config/'
    '*.env*'
    '*.log'
    '*.sample*'
    '*.sops'
    '*.swp'
    '*~'
    '.DS_Store'
    '.git'
    '.gitignore'
    '.yamllint'
    'acme.json'
    'docker-compose*'
    'README.md'
    'sync.sh'
)
RSYNC_EXCLUDE_PARAMS=()
for ex in "${RSYNC_EXCLUDES[@]}"; do RSYNC_EXCLUDE_PARAMS+=(--exclude "$ex"); done
RSYNC_OPTS=(-az --perms --executability)
TEMP_RSYNC_OPTS=(-az --exclude='*.sops' --perms --executability)
$DRY_RUN && RSYNC_OPTS+=(--dry-run) && TEMP_RSYNC_OPTS+=(--dry-run)
$VERBOSE && RSYNC_OPTS+=(-v) && TEMP_RSYNC_OPTS+=(-v)

# Check if a compose stack is part of the specified profile
profile_matches_group() {
    local file="$1"
    # Match inline array: profiles: [X, Y]
    grep -qiE "profiles:.*\b$GROUP\b" "$file" && return 0
    # Match YAML list format
    awk -v grp="$GROUP" '
        /profiles:/ {found=1; next}
        found && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/,""); if ($0 == grp) {exit 0}}
        found && /^[^[:space:]]/ {found=0}
        END {exit 1}
    ' "$file"
}

# Determine if a service is in the rsync exclusion list
service_is_excluded() { local svc="$1"; [[ " ${RSYNC_EXCLUDES[*]%/} " =~ " $svc " ]]; }

printf "${BLUE}Starting sync for group: '$GROUP'${NC}\n"
for HOST in ${HOSTS[$GROUP]}; do
    echo -e "${BLUE}Syncing Host: $HOST${NC}"
    # Create temporary directories on remote host
    $DRY_RUN || ssh "$HOST" "mkdir -p $TMP_DIR/secrets $TMP_DIR/traefik $TMP_DIR/socket-proxy"
    # Rsync master docker-compose and profile-specific .env file
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/$COMPOSE_FILE" "$HOST:$TMP_DIR/"
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/$ENV_FILE" "$HOST:$TMP_DIR/"
    # Rsync Secrets, Traefik config & Socket Proxy stack
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/secrets/$GROUP/" "$HOST:$TMP_DIR/secrets/$GROUP/"
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/$TRAEFIK_DIR/common/" "$HOST:$TMP_DIR/common/"
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/$TRAEFIK_DIR/$GROUP/" "$HOST:$TMP_DIR/traefik/$GROUP/"
    rsync "${TEMP_RSYNC_OPTS[@]}" "$SCRIPT_DIR/$SOCKET_PROXY_DIR/$GROUP/" "$HOST:$TMP_DIR/socket-proxy/$GROUP/"
    # Move files to their final locations with proper permissions
    if ! $DRY_RUN; then
        ssh -T "$HOST" "
            set -e && DEST='$DEST_DIR' && TMP='$TMP_DIR'
            sudo mkdir -p \$DEST/secrets \$DEST/$TRAEFIK_DIR \$DEST/$SOCKET_PROXY_DIR
            sudo mv \$TMP/$COMPOSE_FILE \$DEST/docker-compose.yaml
            sudo mv \$TMP/$ENV_FILE \$DEST/.env
            [[ -d \$TMP/secrets/$GROUP ]] && sudo cp -a \$TMP/secrets/$GROUP/. \$DEST/secrets/
            [[ -d \$TMP/common ]] && sudo cp -a \$TMP/common/. \$DEST/$TRAEFIK_DIR/
            [[ -d \$TMP/traefik/$GROUP ]] && sudo cp -a \$TMP/traefik/$GROUP/. \$DEST/$TRAEFIK_DIR/
            [[ -d \$TMP/socket-proxy/$GROUP ]] && sudo cp -a \$TMP/socket-proxy/$GROUP/. \$DEST/$SOCKET_PROXY_DIR/
            rm -rf \$TMP
        "
    fi
    # Profile-based Sync of general Services
    printf "${BLUE}Gathering services matching ${GROUP} profile...${NC}\n"
    mapfile -t SERVICES < <(find "$SCRIPT_DIR/services" -name "compose.yaml" -type f)
    INCLUDED_SVCS=()
    # Evaluate each service for profile match with the specified group
    for svc in "${SERVICES[@]}"; do
        dir=$(dirname "${svc#$SCRIPT_DIR/services/}")
        service_is_excluded "${dir%%/*}" && continue
        if profile_matches_group "$svc"; then
            echo -e "${GREEN}[OK] Service: $dir${NC}"
            INCLUDED_SVCS+=("--include=/$dir/" "--include=/$dir/**")
        elif ! grep -qi "profiles:" "$svc"; then
            $VERBOSE && echo -e "${RED}[KO] Service: $dir (No profile set)${NC}"
        else
            $VERBOSE && echo -e "${RED}[KO] Service: $dir (Profile mismatch)${NC}"
        fi
    done
    # Rsync profile-matched services
    if [ ${#INCLUDED_SVCS[@]} -gt 0 ]; then
        rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_PARAMS[@]}" \
            "${INCLUDED_SVCS[@]}" --exclude='*' \
            "$SCRIPT_DIR/services/" "$HOST:$DEST_DIR/services/"
    fi
    # Clean up any .sops files on remote host
    $DRY_RUN || ssh "$HOST" "find ~/ -type f -name "*.sops*" 2> /dev/null | xargs rm -f"
done

echo -e "${GREEN}Sync completed successfully for $GROUP.${NC}"
