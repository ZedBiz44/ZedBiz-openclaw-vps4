#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

openclaw_home="/home/openclaw"
env_file="$openclaw_home/.config/openclaw/1password.env"
config_file="$openclaw_home/.openclaw/openclaw.json"
gateway_token_file="$openclaw_home/.config/openclaw/gateway-token"
dropin_dir="$openclaw_home/.config/systemd/user/openclaw-gateway.service.d"
runtime_dir="/run/user/$(id -u openclaw)"
secure_bin_dir="$openclaw_home/.local/secure-bin"
op_command="$secure_bin_dir/op"

if [[ ! -s "$env_file" ]]; then
  echo "Missing protected 1Password service-account environment file: $env_file" >&2
  exit 1
fi

if ! command -v op >/dev/null 2>&1; then
  install -d -m 0755 /usr/share/keyrings
  curl -sS https://downloads.1password.com/linux/keys/1password.asc \
    | gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
  printf 'deb [arch=%s signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/%s stable main\n' \
    "$(dpkg --print-architecture)" "$(dpkg --print-architecture)" \
    > /etc/apt/sources.list.d/1password.list
  install -d -m 0755 /etc/debsig/policies/AC2D62742012EA22 /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
    > /etc/debsig/policies/AC2D62742012EA22/1password.pol
  curl -sS https://downloads.1password.com/linux/keys/1password.asc \
    | gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y 1password-cli
fi

# OpenClaw intentionally requires exec SecretRef commands to be owned by the
# Gateway user. Keep the trusted copy in a root-controlled directory so another
# file cannot be substituted through a user-writable parent directory.
install -d -o root -g root -m 0755 "$secure_bin_dir"
install -o openclaw -g openclaw -m 0555 /usr/bin/op "$op_command"

chown openclaw:openclaw "$env_file"
chmod 0600 "$env_file"

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a
sudo -u openclaw env OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" op whoami >/dev/null
sudo -u openclaw env OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" \
  op read 'op://openclaw-agents-shared/openrouter-api-key/credential' >/dev/null
unset OP_SERVICE_ACCOUNT_TOKEN

if [[ "$(jq -r '.gateway.auth.token | type' "$config_file")" == "string" ]]; then
  umask 077
  jq -r '.gateway.auth.token' "$config_file" > "$gateway_token_file"
  chown openclaw:openclaw "$gateway_token_file"
  chmod 0600 "$gateway_token_file"
fi

tmp_config="$(mktemp)"
jq '
  .secrets.providers.onepassword_openrouter = {
    source: "exec",
    command: "/home/openclaw/.local/secure-bin/op",
    trustedDirs: ["/home/openclaw/.local/secure-bin"],
    args: ["read", "op://openclaw-agents-shared/openrouter-api-key/credential"],
    passEnv: ["HOME", "OP_SERVICE_ACCOUNT_TOKEN"],
    jsonOnly: false,
    timeoutMs: 15000
  }
  | .secrets.providers.gateway_token_file = {
    source: "file",
    path: "/home/openclaw/.config/openclaw/gateway-token",
    mode: "singleValue"
  }
  | .models.providers.openrouter.apiKey = {
    source: "exec",
    provider: "onepassword_openrouter",
    id: "value"
  }
  | .gateway.auth.token = {
    source: "file",
    provider: "gateway_token_file",
    id: "value"
  }
' "$config_file" > "$tmp_config"
chown openclaw:openclaw "$tmp_config"
chmod 0600 "$tmp_config"
mv "$tmp_config" "$config_file"

install -d -o openclaw -g openclaw -m 0755 "$dropin_dir"
cat > "$dropin_dir/10-1password.conf" <<EOF
[Service]
EnvironmentFile=$env_file
EOF
chown openclaw:openclaw "$dropin_dir/10-1password.conf"
chmod 0644 "$dropin_dir/10-1password.conf"

sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user daemon-reload
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user restart openclaw-gateway.service
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user is-active --quiet openclaw-gateway.service

echo "1Password SecretRef for OpenRouter is active"
