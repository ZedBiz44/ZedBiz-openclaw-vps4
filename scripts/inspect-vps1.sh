#!/usr/bin/env bash
set -euo pipefail

echo CADDY_MOUNTS
docker inspect caddy --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'

echo CADDY_ROUTES
docker exec caddy sh -lc \
  'grep -nE "^[[:alnum:]*._-]+\.zbiz\.ca|reverse_proxy" /etc/caddy/Caddyfile | head -80'

echo TERRY_CONFIG
docker exec terry sh -lc '
  for f in /home/node/.openclaw/openclaw.json /home/node/.openclaw/config.json /root/.openclaw/openclaw.json; do
    if [ -f "$f" ]; then echo "$f"; fi
  done'

echo TERRY_MODELS
docker exec terry sh -lc '
  jq -r ".agents.defaults.models // {} | keys[]" /home/node/.openclaw/openclaw.json 2>/dev/null || true
  echo FALLBACKS
  jq -r ".agents.defaults.model.fallbacks[]?" /home/node/.openclaw/openclaw.json 2>/dev/null || true
  echo PRIMARY
  jq -r ".agents.defaults.model.primary // empty" /home/node/.openclaw/openclaw.json 2>/dev/null || true'

echo WIKI_ACCESS
namei -l /opt/openclaw/shared/knowledge/wiki
find /opt/openclaw/shared/knowledge/wiki -maxdepth 1 -type f -printf '%M %u:%g %f\n' 2>/dev/null | head -20 || true

echo RSYNC_JOBS
find /home/jackadmin /opt/openclaw -maxdepth 4 -type f \
  \( -iname '*rsync*' -o -iname '*sync*wiki*' \) 2>/dev/null | head -50 || true
