#!/usr/bin/env bash
set -euo pipefail

tunnel_pub="${1:-/tmp/vps1-caddy-tunnel.pub}"
wiki_pub="${2:-/tmp/vps1-wiki-rsync.pub}"
authorized_keys="/home/jackadmin/.ssh/authorized_keys"

[[ -f "$tunnel_pub" ]] || { echo "Missing tunnel public key" >&2; exit 1; }
[[ -f "$wiki_pub" ]] || { echo "Missing wiki public key" >&2; exit 1; }
command -v rrsync >/dev/null

tunnel_key="$(cat "$tunnel_pub")"
wiki_key="$(cat "$wiki_pub")"

tunnel_line="command=\"/usr/bin/sleep infinity\",restrict,port-forwarding,permitlisten=\"127.0.0.1:3012\" $tunnel_key"
wiki_line="command=\"/usr/bin/rrsync -ro /opt/openclaw/shared/knowledge/wiki\",restrict $wiki_key"

grep -Fqx "$tunnel_line" "$authorized_keys" || printf '%s\n' "$tunnel_line" >> "$authorized_keys"
grep -Fqx "$wiki_line" "$authorized_keys" || printf '%s\n' "$wiki_line" >> "$authorized_keys"

chmod 0600 "$authorized_keys"
echo "Rocky's restricted VPS1 keys are authorized"

