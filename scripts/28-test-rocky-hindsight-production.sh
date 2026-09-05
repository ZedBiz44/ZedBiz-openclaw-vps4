#!/usr/bin/env bash
set -euo pipefail

bank_id="${ROCKY_HINDSIGHT_BANK:-rocky-vps4-main::unknown::anonymous}"
base_url="${HINDSIGHT_URL:-http://127.0.0.1:9077}"
marker="ROCKY-DOCKER-RECOVERY-$(date +%s)"
restore_db="rocky_hindsight_restore_test_$$"
response_file="$(mktemp)"
dump_file="$(mktemp)"

cleanup() {
  docker exec rocky-hindsight-db dropdb -U hindsight_user --if-exists "$restore_db" >/dev/null 2>&1 || true
  curl -fsS -X DELETE \
    "$base_url/v1/default/banks/$bank_id/documents/rocky-production-recovery-test" \
    >/dev/null 2>&1 || true
  rm -f "$response_file" "$dump_file"
}
trap cleanup EXIT

recall_marker() {
  local started elapsed
  started="$(date +%s%3N)"
  jq -n --arg query "What is Rocky's new Docker memory recovery verification code?" \
    '{query:$query,types:["world","experience","observation"],budget:"mid",max_tokens:2048}' \
    | curl -fsS --max-time 60 -H 'Content-Type: application/json' -d @- \
      "$base_url/v1/default/banks/$bank_id/memories/recall" >"$response_file"
  elapsed=$(( $(date +%s%3N) - started ))
  grep -Fq "$marker" "$response_file"
  printf 'Recall passed in %s ms.\n' "$elapsed"
}

/usr/local/sbin/rocky-hindsight-health

jq -n --arg marker "$marker" \
  '{async:false,items:[{content:("Rocky new Docker memory recovery verification code is " + $marker + "."),document_id:"rocky-production-recovery-test",timestamp:"unset",update_mode:"replace",strategy:"verbatim",tags:["production-test"],metadata:{source_system:"rocky-production-test"}}]}' \
  | curl -fsS --max-time 300 -H 'Content-Type: application/json' -d @- \
    "$base_url/v1/default/banks/$bank_id/memories" >/dev/null

recall_marker
systemctl restart rocky-hindsight.service
for _ in $(seq 1 60); do
  curl -fsS --max-time 3 "$base_url/health" >/dev/null 2>&1 && break
  sleep 3
done
/usr/local/sbin/rocky-hindsight-health
recall_marker

minimum_documents="$(docker exec rocky-hindsight-db psql -U hindsight_user -d hindsight_db -Atc 'select count(*) from documents')"
/usr/local/sbin/rocky-hindsight-backup
latest_backup="$(find /opt/backups/hindsight/rocky -maxdepth 1 -type f -name '*.dump.age' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -s "$latest_backup" ]]
age -d -i /etc/rocky-hindsight/backup-age.key -o "$dump_file" "$latest_backup"
docker exec -i rocky-hindsight-db pg_restore --list <"$dump_file" >/dev/null

docker exec rocky-hindsight-db createdb -U hindsight_user "$restore_db"
docker exec -i rocky-hindsight-db pg_restore -U hindsight_user -d "$restore_db" --no-owner --no-privileges <"$dump_file"

restore_counts="$(docker exec rocky-hindsight-db psql -U hindsight_user -d "$restore_db" -Atc 'select (select count(*) from documents) || '"'"':'"'"' || (select count(*) from memory_units)')"
restore_documents="${restore_counts%%:*}"
[[ "$restore_documents" -ge "$minimum_documents" ]]
restored_marker_count="$(docker exec rocky-hindsight-db psql -U hindsight_user -d "$restore_db" -Atc \
  "select count(*) from documents where id = 'rocky-production-recovery-test' and original_text like '%$marker%'")"
[[ "$restored_marker_count" -eq 1 ]]

printf 'Restart recall passed; encrypted-backup restore passed with document:memory counts %s and the test memory intact.\n' "$restore_counts"
