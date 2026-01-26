#!/bin/sh
set -eu

: "${FQDN:?FQDN must be set}"

TEMPLATE="/templates/mailrise.yaml"
OUTPUT="/tmp/mailrise.yaml"

echo "Generating Mailrise config for mail.$FQDN..."
sed "s|\${FQDN}|$FQDN|g" "$TEMPLATE" > "$OUTPUT"

export PYTHONPATH="/home/mailrise/.local/lib/python*/site-packages"

echo "Starting Mailrise with config at $OUTPUT..."
exec mailrise "$OUTPUT"
