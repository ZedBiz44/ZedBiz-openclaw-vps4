#!/usr/bin/env bash
set -euo pipefail

base_url="${HINDSIGHT_URL:-http://127.0.0.1:9077}"
bank_id="${ROCKY_HINDSIGHT_BANK:-rocky-vps4-main::unknown::anonymous}"
workers="${ROCKY_HINDSIGHT_WORKERS:-4}"
workspace=/home/openclaw/.openclaw/workspace
manifest="$(mktemp)"
results="$(mktemp)"
trap 'rm -f "$manifest" "$results"' EXIT

[[ "$workers" =~ ^[1-9][0-9]*$ ]] || {
  echo "ROCKY_HINDSIGHT_WORKERS must be a positive whole number." >&2
  exit 1
}

{
  printf '%s\n' "$workspace/MEMORY.md"
  find "$workspace/shared-memory-wiki" -type f -name '*.md' -print | sort
} >"$manifest"

if [[ -n "${ROCKY_HINDSIGHT_SOURCE_FILE:-}" ]]; then
  source_file="$(realpath "$ROCKY_HINDSIGHT_SOURCE_FILE")"
  [[ "$source_file" == "$workspace/"* && -s "$source_file" ]] || {
    echo "ROCKY_HINDSIGHT_SOURCE_FILE must be a non-empty file inside Rocky's workspace." >&2
    exit 1
  }
  printf '%s\n' "$source_file" >"$manifest"
fi

if [[ "${ROCKY_HINDSIGHT_MAX_FILES:-0}" =~ ^[1-9][0-9]*$ ]]; then
  head -n "$ROCKY_HINDSIGHT_MAX_FILES" "$manifest" >"$manifest.limited"
  mv "$manifest.limited" "$manifest"
fi

total="$(wc -l <"$manifest")"

ingest_path() {
  local path="$1" relative document_id body_file response_file
  [[ -s "$path" ]] || return 0
  relative="${path#"$workspace/"}"
  document_id="rocky-baseline-$(printf '%s' "$relative" | sha256sum | cut -c1-24)"
  body_file="$(mktemp)"
  response_file="$(mktemp)"
  jq -Rs --arg document_id "$document_id" --arg source "$relative" \
    '{async:false,items:[{content:.,document_id:$document_id,timestamp:"unset",update_mode:"replace",strategy:"verbatim",tags:["rocky-baseline","source:markdown"],metadata:{source_system:"rocky-vps4-workspace",source_path:$source,approved_baseline:"true"}}]}' \
    <"$path" >"$body_file"
  if curl -fsS --max-time 300 -H 'Content-Type: application/json' \
    --data-binary "@$body_file" -o "$response_file" "$base_url/v1/default/banks/$bank_id/memories"; then
    printf 'ok\t%s\n' "$relative" >>"$results"
  else
    printf 'failed\t%s\n' "$relative" >>"$results"
    {
      printf 'Failed: %s\n' "$relative"
      sed -n '1,8p' "$response_file"
    } >&2
  fi
  rm -f "$body_file" "$response_file"
}

while IFS= read -r path; do
  [[ -s "$path" ]] || continue
  ingest_path "$path" &
  while (( $(jobs -pr | wc -l) >= workers )); do
    wait -n || true
  done
done <"$manifest"
wait || true

completed="$(awk -F '\t' '$1 == "ok" { count++ } END { print count + 0 }' "$results")"
failed="$(awk -F '\t' '$1 == "failed" { count++ } END { print count + 0 }' "$results")"

printf 'Rocky baseline ingestion: %s completed, %s failed, %s discovered.\n' \
  "$completed" "$failed" "$total"
[[ "$failed" -eq 0 ]]
