#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

openclaw_home="/home/openclaw"
runtime_dir="/run/user/$(id -u openclaw)"
wrapper="$openclaw_home/bin/rocky-asana-mcp"

install -d -o openclaw -g openclaw -m 0755 "$openclaw_home/bin"
cat > "$wrapper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/openclaw
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
cd /home/openclaw
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a
ASANA_ACCESS_TOKEN="$(/home/openclaw/.local/secure-bin/op read 'op://agent-rocky/asana-api-key-rocky/credential')"
export ASANA_ACCESS_TOKEN
exec /usr/bin/npx -y @roychri/mcp-server-asana
EOF
chown openclaw:openclaw "$wrapper"
chmod 0700 "$wrapper"

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  /home/openclaw/.npm-global/bin/openclaw mcp set asana \
  '{"command":"/home/openclaw/bin/rocky-asana-mcp","args":[],"timeoutSeconds":60}'

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  /home/openclaw/.npm-global/bin/openclaw mcp doctor
probe_json="$(sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  /home/openclaw/.npm-global/bin/openclaw mcp probe asana --json)"
printf '%s\n' "$probe_json"
jq -e '(.diagnostics | length) == 0 and (.tools | length) > 0' <<<"$probe_json" >/dev/null

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  /home/openclaw/.npm-global/bin/openclaw mcp reload asana 2>/dev/null || true

echo "Rocky's PAT-backed Asana MCP is configured and probeable"
