#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

openclaw_home="/home/openclaw"
openclaw_bin="$openclaw_home/.npm-global/bin/openclaw"
config_file="$openclaw_home/.openclaw/openclaw.json"
env_file="$openclaw_home/.config/openclaw/1password.env"
runtime_dir="/run/user/$(id -u openclaw)"
patch_file="$(mktemp)"
backup_file="$config_file.before-telegram-slack-$(date +%Y%m%d-%H%M%S)"

cleanup() {
  rm -f "$patch_file"
}
trap cleanup EXIT

if [[ ! -s "$env_file" ]]; then
  echo "Missing protected 1Password environment file: $env_file" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

run_openclaw() {
  runuser -u openclaw -- env \
    HOME="$openclaw_home" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" \
    "$openclaw_bin" "$@"
}

read_secret() {
  runuser -u openclaw -- env \
    HOME="$openclaw_home" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" \
    /home/openclaw/.local/secure-bin/op read "$1"
}

telegram_token="$(read_secret 'op://agent-rocky/telegram-bot-token-rocky/credential')"
slack_app_token="$(read_secret 'op://agent-rocky/slack-app-token-rocky/credential')"
slack_bot_token="$(read_secret 'op://agent-rocky/slack-bot-token-rocky/credential')"

[[ "$telegram_token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]] || {
  echo "Telegram credential does not match BotFather token format." >&2
  exit 1
}
[[ "$slack_app_token" == xapp-* ]] || {
  echo "Slack app-level credential must begin with xapp-." >&2
  exit 1
}
[[ "$slack_bot_token" == xoxb-* ]] || {
  echo "Slack bot OAuth credential must begin with xoxb-." >&2
  exit 1
}
unset telegram_token slack_app_token slack_bot_token

# Telegram is bundled with OpenClaw. Slack is an official channel plugin.
if ! run_openclaw plugins list --json 2>/dev/null \
  | jq -e '.plugins[]? | select(.id == "slack" and .status == "enabled")' >/dev/null; then
  run_openclaw plugins install @openclaw/slack
fi

cat >"$patch_file" <<'JSON'
{
  "secrets": {
    "providers": {
      "onepassword_telegram": {
        "source": "exec",
        "command": "/home/openclaw/.local/secure-bin/op",
        "trustedDirs": ["/home/openclaw/.local/secure-bin"],
        "args": ["read", "op://agent-rocky/telegram-bot-token-rocky/credential"],
        "passEnv": ["HOME", "OP_SERVICE_ACCOUNT_TOKEN"],
        "jsonOnly": false,
        "timeoutMs": 15000
      },
      "onepassword_slack_app": {
        "source": "exec",
        "command": "/home/openclaw/.local/secure-bin/op",
        "trustedDirs": ["/home/openclaw/.local/secure-bin"],
        "args": ["read", "op://agent-rocky/slack-app-token-rocky/credential"],
        "passEnv": ["HOME", "OP_SERVICE_ACCOUNT_TOKEN"],
        "jsonOnly": false,
        "timeoutMs": 15000
      },
      "onepassword_slack_bot": {
        "source": "exec",
        "command": "/home/openclaw/.local/secure-bin/op",
        "trustedDirs": ["/home/openclaw/.local/secure-bin"],
        "args": ["read", "op://agent-rocky/slack-bot-token-rocky/credential"],
        "passEnv": ["HOME", "OP_SERVICE_ACCOUNT_TOKEN"],
        "jsonOnly": false,
        "timeoutMs": 15000
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": {
        "source": "exec",
        "provider": "onepassword_telegram",
        "id": "value"
      },
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    },
    "slack": {
      "enabled": true,
      "mode": "socket",
      "appToken": {
        "source": "exec",
        "provider": "onepassword_slack_app",
        "id": "value"
      },
      "botToken": {
        "source": "exec",
        "provider": "onepassword_slack_bot",
        "id": "value"
      },
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    }
  },
  "plugins": {
    "allow": ["slack"]
  },
  "gateway": {
    "trustedProxies": ["127.0.0.1", "::1"]
  }
}
JSON

chown openclaw:openclaw "$patch_file"
chmod 0600 "$patch_file"

run_openclaw config patch --file "$patch_file" --dry-run
cp -a "$config_file" "$backup_file"
run_openclaw config patch --file "$patch_file"
run_openclaw config validate

systemctl --user -M openclaw@ daemon-reload
systemctl --user -M openclaw@ restart openclaw-gateway.service
sleep 8
systemctl --user -M openclaw@ is-active --quiet openclaw-gateway.service

run_openclaw channels status --probe --json
run_openclaw secrets audit

echo "Rocky Telegram and Slack configuration applied."
