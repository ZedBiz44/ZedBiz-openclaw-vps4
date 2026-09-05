#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

openclaw_home="/home/openclaw"
openclaw_bin="$openclaw_home/.npm-global/bin/openclaw"
config_file="$openclaw_home/.openclaw/openclaw.json"
agents_file="$openclaw_home/.openclaw/workspace/AGENTS.md"
env_file="$openclaw_home/.config/openclaw/1password.env"
runtime_dir="/run/user/$(id -u openclaw)"
plugin_version="0.11.1"
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
  | jq -e --arg version "$plugin_version" \
    '.plugins[]? | select(.id == "hindsight-openclaw" and .version == $version)' >/dev/null; then
  run_openclaw plugins install --force --pin \
    "@vectorize-io/hindsight-openclaw@$plugin_version"
fi

cat >"$patch_file" <<'JSON'
{
  "tools": {
    "alsoAllow": ["agent_knowledge_ingest"]
  },
  "plugins": {
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
          "hindsightApiUrl": "http://127.0.0.1:9077",
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

# Preserve any other explicitly allowed tools while ensuring Rocky can use the
# Hindsight knowledge-ingest tool from his restricted coding profile.
current_also_allow="$(jq -c '[(.tools.alsoAllow // [])[], "agent_knowledge_ingest"] | unique' "$config_file")"
jq --argjson also_allow "$current_also_allow" '.tools.alsoAllow = $also_allow' \
  "$patch_file" >"$patch_file.merged"
mv "$patch_file.merged" "$patch_file"

chown openclaw:openclaw "$patch_file"
chmod 0600 "$patch_file"

run_openclaw config patch --file "$patch_file" --dry-run
run_openclaw config patch --file "$patch_file"
for old_key in \
  apiPort daemonIdleTimeout embedVersion llmProvider llmBaseUrl llmApiKey llmModel; do
  run_openclaw config unset \
    "plugins.entries.hindsight-openclaw.config.${old_key}" >/dev/null 2>&1 || true
done
run_openclaw config validate

if [[ -f "$agents_file" ]]; then
  sed -i \
    -e 's/version `0.9.0` owns/version `0.11.1` owns/' \
    -e 's#^- Hindsight.*API and PostgreSQL store run locally on VPS4.*#- The Hindsight API 0.9.1 and PostgreSQL 18.6 run in separate Docker containers on VPS4. The extraction model uses the existing 1Password-backed OpenRouter SecretRef; never reveal or store the secret value.#' \
    -e 's#^- Rocky.*ten non-empty historical OpenClaw sessions were backfilled on 2026-07-24 with zero failures.*#- The clean database was loaded on 2026-09-04 from Rocky curated MEMORY.md and all 758 approved shared-wiki Markdown pages.#' \
    -e 's#^- Existing Markdown and SQLite memory remain in place as additional layers.*#- Rocky workspace Markdown and OpenClaw session history remain separate supporting layers. The failed embedded Hindsight database was discarded after the clean replacement passed.#' \
    "$agents_file"
fi

systemctl is-active --quiet rocky-hindsight.service
curl -fsS --max-time 10 http://127.0.0.1:9077/health >/dev/null
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
  | jq -e --arg version "$plugin_version" \
    '.plugins[]? | select(.id == "hindsight-openclaw" and .status == "loaded" and .version == $version)' \
  >/dev/null
if ! run_openclaw secrets audit --allow-exec; then
  echo "OpenClaw reported an existing secret-resolution warning; Hindsight itself is configured without plaintext secrets." >&2
fi

echo "Rocky's Hindsight memory provider is installed and healthy."
