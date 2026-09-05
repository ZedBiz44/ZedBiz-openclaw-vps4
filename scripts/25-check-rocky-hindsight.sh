#!/usr/bin/env bash
set -euo pipefail

[[ "$(docker inspect -f '{{.State.Health.Status}}' rocky-hindsight-db)" == healthy ]]
[[ "$(docker inspect -f '{{.State.Health.Status}}' rocky-hindsight-api)" == healthy ]]
curl -fsS --max-time 10 http://127.0.0.1:9077/health \
  | jq -e '.status == "healthy" and .database == "connected"' >/dev/null

while IFS= read -r bank_id; do
  curl -fsS --max-time 15 \
    "http://127.0.0.1:9077/v1/default/banks/$bank_id/stats" \
    | jq -e '.failed_operations == 0 and .failed_consolidation == 0' >/dev/null
done < <(
  curl -fsS --max-time 15 http://127.0.0.1:9077/v1/default/banks \
    | jq -r '.banks[].bank_id'
)

settings="$(docker exec rocky-hindsight-db psql -U hindsight_user -d hindsight_db -Atc \
  "select name || '=' || setting from pg_settings where name in ('fsync','synchronous_commit','full_page_writes','data_checksums') order by name")"
grep -Fqx 'data_checksums=on' <<<"$settings"
grep -Fqx 'fsync=on' <<<"$settings"
grep -Fqx 'full_page_writes=on' <<<"$settings"
grep -Fqx 'synchronous_commit=on' <<<"$settings"

echo "Rocky Hindsight database and API are healthy; safe-write settings are enabled."
