#!/usr/bin/env bash
set -euo pipefail

caddy_gateway="${CADDY_GATEWAY:-172.18.0.1}"
caddyfile="/opt/caddy/Caddyfile"
route="rocky.zbiz.ca {
    reverse_proxy ${caddy_gateway}:3013
}"

if ! docker image inspect zedbiz/rocky-tunnel-bridge:1 >/dev/null 2>&1; then
  docker build -t zedbiz/rocky-tunnel-bridge:1 -f /tmp/rocky-tunnel-bridge.Dockerfile /tmp
fi

docker rm -f rocky-tunnel-bridge >/dev/null 2>&1 || true
docker run -d \
  --name rocky-tunnel-bridge \
  --restart unless-stopped \
  --network host \
  zedbiz/rocky-tunnel-bridge:1 \
  -d -d TCP-LISTEN:3013,bind="$caddy_gateway",reuseaddr,fork TCP:127.0.0.1:3012

if ! docker run --rm -v /opt/caddy:/data alpine:3.22 grep -q '^rocky\.zbiz\.ca {' /data/Caddyfile; then
  printf '\n%s\n' "$route" > /tmp/rocky-caddy-route
  docker run --rm \
    -v /opt/caddy:/data \
    -v /tmp/rocky-caddy-route:/tmp/rocky-caddy-route:ro \
    alpine:3.22 sh -c 'cat /tmp/rocky-caddy-route >> /data/Caddyfile'
fi

docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

echo "VPS1 Caddy route for rocky.zbiz.ca is configured"
