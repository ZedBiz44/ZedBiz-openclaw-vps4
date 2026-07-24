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
plugin_version="0.9.0"
patch_file="$(mktemp)"
uv_installer=""
backup_file="$config_file.before-hindsight-$(date +%Y%m%d-%H%M%S)"

cleanup() {
  rm -f "$patch_file"
  [[ -z "$uv_installer" ]] || rm -f "$uv_installer"
}
trap cleanup EXIT

[[ -s "$env_file" ]] || {
  echo "Missing protected 1Password environment file: $env_file" >&2
  exit 1
}

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

if [[ ! -x "$openclaw_home/.local/bin/uvx" ]]; then
  install -d -o openclaw -g openclaw -m 0755 \
    "$openclaw_home/.local/bin"
  uv_installer="$(mktemp)"
  curl --proto '=https' --tlsv1.2 -LsSf \
    https://astral.sh/uv/0.11.31/install.sh -o "$uv_installer"
  chown openclaw:openclaw "$uv_installer"
  chmod 0700 "$uv_installer"
  runuser -u openclaw -- env \
    HOME="$openclaw_home" \
    UV_INSTALL_DIR="$openclaw_home/.local/bin" \
    UV_NO_MODIFY_PATH=1 \
    sh "$uv_installer"
fi

install -d -o openclaw -g openclaw -m 0755 \
  "$openclaw_home/.local/share" \
  "$openclaw_home/.local/share/uv" \
  "$openclaw_home/.local/share/uv/tools"

runuser -u openclaw -- env \
  HOME="$openclaw_home" \
  PATH="$openclaw_home/.local/bin:/usr/bin:/bin" \
  uvx --version

cp -a "$config_file" "$backup_file"

if ! run_openclaw plugins list --json 2>/dev/null \
  | jq -e '.plugins[]? | select(.id == "hindsight-openclaw" and .version == "0.9.0")' >/dev/null; then
  run_openclaw plugins install --pin \
    "@vectorize-io/hindsight-openclaw@$plugin_version"
fi

cat >"$patch_file" <<'JSON'
{
  "plugins": {
    "allow": ["slack", "hindsight-openclaw"],
    "slots": {
      "memory": "hindsight-openclaw"
    },
    "entries": {
      "hindsight-openclaw": {
        "enabled": true,
        "hooks": {
          "allowConversationAccess": true
        },
        "config": {
          "apiPort": 9077,
          "daemonIdleTimeout": 0,
          "embedVersion": "latest",
          "llmProvider": "openai",
          "llmBaseUrl": "https://openrouter.ai/api/v1",
          "llmApiKey": {
            "source": "exec",
            "provider": "onepassword_openrouter",
            "id": "value"
          },
          "llmModel": "google/gemini-3.1-flash-lite",
          "dynamicBankId": true,
          "bankIdPrefix": "rocky-vps4",
          "dynamicBankGranularity": ["agent", "channel", "user"],
          "retainTags": [
            "source_system:openclaw",
            "agent:rocky",
            "environment:vps4"
          ],
          "retainSource": "openclaw-rocky-vps4",
          "autoRecall": true,
          "autoRetain": true,
          "retainRoles": ["user", "assistant"],
          "retainFormat": "json",
          "retainToolCalls": true,
          "retainEveryNTurns": 1,
          "recallBudget": "mid",
          "recallMaxTokens": 2048,
          "recallTypes": ["world", "experience", "observation"],
          "recallContextTurns": 3,
          "recallMaxQueryChars": 1600,
          "recallTopK": 8,
          "recallTimeoutMs": 60000,
          "enableKnowledgeTools": true,
          "retainExtractionMode": "verbose",
          "enableObservations": true,
          "enableAutoConsolidation": true,
          "dispositionSkepticism": 4,
          "dispositionLiteralism": 4,
          "dispositionEmpathy": 4,
          "entityLabels": [
            {"key": "person", "type": "text", "description": "A human user, VA, client or contact"},
            {"key": "business", "type": "text", "description": "A business, client company or organization"},
            {"key": "project", "type": "text", "description": "A ZedBiz project, campaign, website or automation"},
            {"key": "task", "type": "text", "description": "An assignment, decision, status, blocker or handoff"}
          ],
          "retainMission": "Retain durable user preferences, decisions, corrections, assignments, project context, client context, task status, blockers, lessons learned and handoff cues. Do not retain secrets, credentials, raw logs, temporary troubleshooting noise, trivial chatter or unsupported claims.",
          "observationsMission": "Synthesize stable preferences, recurring operating patterns, active projects, verified decisions, reliable lessons and unresolved handoffs. Keep people and private VA work isolated by the current bank.",
          "bankMission": "Rocky is the ZedBiz virtual assistant. Use memory to provide continuity while respecting user and channel isolation. Verify current facts against live systems, GitHub, the Shared Memory Wiki and Notion before acting."
        }
      }
    }
  }
}
JSON

chown openclaw:openclaw "$patch_file"
chmod 0600 "$patch_file"

run_openclaw config patch --file "$patch_file" --dry-run
run_openclaw config patch --file "$patch_file"
run_openclaw config validate

systemctl --user -M openclaw@ restart openclaw-gateway.service

for _ in $(seq 1 30); do
  if systemctl --user -M openclaw@ is-active --quiet openclaw-gateway.service \
    && curl -fsS --max-time 3 http://127.0.0.1:9077/health >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

systemctl --user -M openclaw@ is-active --quiet openclaw-gateway.service
curl -fsS --max-time 10 http://127.0.0.1:9077/health >/dev/null
run_openclaw plugins list --json \
  | jq -e '.plugins[]? | select(.id == "hindsight-openclaw" and .status == "loaded" and .version == "0.9.0")' \
  >/dev/null
run_openclaw secrets audit

echo "Rocky's Hindsight memory provider is installed and healthy."
