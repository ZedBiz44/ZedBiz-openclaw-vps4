#!/usr/bin/env bash
set -euo pipefail

backup_dir=/opt/backups/hindsight/rocky
config_dir=/etc/rocky-hindsight
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S-MDT)"
plain_file="$backup_dir/rocky-hindsight-$timestamp.dump"
encrypted_file="$plain_file.age"
recipient="$(cat "$config_dir/backup-age-recipient.txt")"

install -d -o root -g openclaw -m 0750 "$backup_dir"
available_kb="$(df -Pk "$backup_dir" | awk 'NR==2 {print $4}')"
if (( available_kb < 1048576 )); then
  echo "Backup stopped: less than 1 GB free on VPS4." >&2
  exit 1
fi

cleanup() {
  rm -f "$plain_file"
}
trap cleanup EXIT

docker exec rocky-hindsight-db sh -ec \
  'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -U hindsight_user -d hindsight_db -Fc' \
  >"$plain_file"

[[ -s "$plain_file" ]]
docker exec -i rocky-hindsight-db pg_restore --list <"$plain_file" >/dev/null
sha256sum "$plain_file" >"$plain_file.sha256"
age -r "$recipient" -o "$encrypted_file" "$plain_file"
chmod 0640 "$encrypted_file" "$plain_file.sha256"
chown root:openclaw "$encrypted_file" "$plain_file.sha256"

if [[ -s "$config_dir/google-drive-folder-id" ]] \
  && runuser -u openclaw -- /home/openclaw/bin/gog auth list 2>/dev/null \
    | grep -Fq 'jack@zbiz.work'; then
  folder_id="$(tr -d '\r\n' <"$config_dir/google-drive-folder-id")"
  runuser -u openclaw -- /home/openclaw/bin/gog drive upload \
    "$encrypted_file" --parent "$folder_id" --account jack@zbiz.work \
    --no-input --json >/dev/null
  runuser -u openclaw -- /home/openclaw/bin/gog drive upload \
    "$plain_file.sha256" --parent "$folder_id" --account jack@zbiz.work \
    --no-input --json >/dev/null
  touch "$encrypted_file.uploaded"
  chown root:openclaw "$encrypted_file.uploaded"
  chmod 0640 "$encrypted_file.uploaded"
else
  echo "Google upload not configured; verified encrypted local backup retained." >&2
fi

find "$backup_dir" -maxdepth 1 -type f -name 'rocky-hindsight-*' -mtime +7 -delete
echo "Verified Rocky Hindsight backup: $encrypted_file"
