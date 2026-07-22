#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
openclaw_path="/home/openclaw/.npm-global/bin/openclaw"
workspace="/home/openclaw/.openclaw/workspace"
gateway_token="$(openssl rand -hex 32)"
runtime_dir="/run/user/$(id -u openclaw)"

sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" onboard \
  --non-interactive \
  --accept-risk \
  --mode local \
  --auth-choice skip \
  --workspace "$workspace" \
  --gateway-bind loopback \
  --gateway-port 18789 \
  --gateway-auth token \
  --gateway-token "$gateway_token" \
  --tailscale off \
  --install-daemon \
  --daemon-runtime node \
  --skip-channels \
  --skip-search \
  --skip-skills \
  --skip-hooks \
  --skip-ui \
  --skip-health \
  --suppress-gateway-token-output

sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" config set session.dmScope '"per-channel-peer"' --strict-json

sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" config set gateway.controlUi.allowedOrigins \
  '["https://rocky.zbiz.ca"]' --strict-json

model_allowlist="$(jq -c . "$repo_dir/config/model-allowlist.json")"
sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" config set agents.defaults.models "$model_allowlist" --strict-json --replace

sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" models set xai/grok-4.3

sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
  "$openclaw_path" models fallbacks clear

for model in \
  openrouter/anthropic/claude-sonnet-4.6 \
  openrouter/google/gemini-3.1-pro-preview \
  openrouter/deepseek/deepseek-v4-pro \
  openrouter/moonshotai/kimi-k2.6; do
  sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
    "$openclaw_path" models fallbacks add "$model"
done

override_dir="/home/openclaw/.config/systemd/user/openclaw-gateway.service.d"
install -d -o openclaw -g openclaw -m 0755 "$override_dir"
cat > "$override_dir/override.conf" <<'EOF'
[Service]
Environment=OPENCLAW_NO_RESPAWN=1
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
Restart=always
RestartSec=2
TimeoutStartSec=90
EOF
chown openclaw:openclaw "$override_dir/override.conf"
chmod 0644 "$override_dir/override.conf"

sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user daemon-reload
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user restart openclaw-gateway.service

chmod 0600 /home/openclaw/.openclaw/openclaw.json
chown -R openclaw:openclaw /home/openclaw/.openclaw

echo "Rocky onboarding and non-secret configuration complete"
