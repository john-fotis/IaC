#!/bin/sh
# /config/entrypoint.sh

# 1. Ensure CF_DNS_API_TOKEN_FILE is set (the path to the secret file)
: "${CF_DNS_API_TOKEN_FILE:?CF_DNS_API_TOKEN_FILE must be set}"

# 2. Read the secret file’s contents into CLOUDFLARE_API_TOKEN
if [ -r "${CF_DNS_API_TOKEN_FILE}" ]; then
  CLOUDFLARE_API_TOKEN=$(cat "${CF_DNS_API_TOKEN_FILE}")
else
  echo "ERROR: Cannot read token at ${CF_DNS_API_TOKEN_FILE}"
  exit 1
fi

# 3. Ensure FQDN is set (injected by Compose via ${FQDN})
: "${FQDN:?FQDN must be set}"

# 4. Extract the base domain from FQDN
BASE_DOMAIN=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')

# 5. Copy the template to a working config (so the template stays clean)
cp /templates/ddclient.conf /config/ddclient.conf

# 6. Ensure the config file is owned by the ddclient user
chown 1000:1000 /config/ddclient.conf

# 7. Ensure the config file is not world-readable
chmod 600 /config/ddclient.conf

# 8. Replace placeholders using sed (delimiter = | to avoid "/" issues)
sed -i "s|\${FQDN}|${BASE_DOMAIN}|g" /config/ddclient.conf
sed -i "s|\${CLOUDFLARE_API_TOKEN}|${CLOUDFLARE_API_TOKEN}|g" /config/ddclient.conf

# 9. Ensure the config file is owned by ddclient user and not writable
chown ${PUID}:${PGID} /config/ddclient.conf
chmod 400 /config/ddclient.conf

# 10. Exec ddclient so it becomes PID 1
exec ddclient -foreground -file /config/ddclient.conf
