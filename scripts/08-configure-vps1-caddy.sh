#!/usr/bin/env bash
set -euo pipefail

caddy_gateway="${CADDY_GATEWAY:-172.18.0.1}"
caddy_subnet="${CADDY_SUBNET:-172.18.0.0/16}"
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

# VPS1 UFW blocks Docker containers from reaching host-bound ports unless an
# explicit rule exists. Limit this rule to Caddy's private Docker subnet and
# the single bridge address/port; the service is not exposed publicly.
docker run --rm --privileged --pid=host -v /:/host alpine:3.22 \
  nsenter -t 1 -n chroot /host \
  ufw allow from "$caddy_subnet" to "$caddy_gateway" port 3013 proto tcp \
  comment 'Rocky Caddy bridge'

if ! docker run --rm -v /opt/caddy:/data alpine:3.22 grep -q '^rocky\.zbiz\.ca {' /data/Caddyfile; then
  printf '\n%s\n' "$route" > /tmp/rocky-caddy-route
  docker run --rm \
    -v /opt/caddy:/data \
    -v /tmp/rocky-caddy-route:/tmp/rocky-caddy-route:ro \
    alpine:3.22 sh -c 'cat /tmp/rocky-caddy-route >> /data/Caddyfile'
fi

docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
docker exec caddy wget -T 5 -q -O /dev/null "http://$caddy_gateway:3013/"

echo "VPS1 Caddy route for rocky.zbiz.ca is configured"
