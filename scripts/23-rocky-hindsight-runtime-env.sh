#!/usr/bin/env bash
set -euo pipefail

umask 077
install -d -o root -g root -m 0700 /run/rocky-hindsight

set -a
# shellcheck disable=SC1091
source /etc/rocky-hindsight/database.env
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a

llm_key="$(runuser -u openclaw -- env \
  HOME=/home/openclaw \
  OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" \
  /home/openclaw/.local/secure-bin/op read \
  'op://openclaw-agents-shared/openrouter-api-key/credential' | tr -d '\r\n')"

[[ -n "$llm_key" ]] || {
  echo "The protected Hindsight model key could not be resolved." >&2
  exit 1
}

tmp_file="$(mktemp /run/rocky-hindsight/runtime.env.XXXXXX)"
printf 'HINDSIGHT_DB_PASSWORD=%s\nHINDSIGHT_API_LLM_API_KEY=%s\n' \
  "$HINDSIGHT_DB_PASSWORD" "$llm_key" >"$tmp_file"
chmod 0600 "$tmp_file"
mv -f "$tmp_file" /run/rocky-hindsight/runtime.env
