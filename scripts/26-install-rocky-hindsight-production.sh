#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir=/etc/rocky-hindsight
service_dir=/opt/rocky-hindsight
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S-MDT)"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-v2 age jq
systemctl enable --now docker.service

install -d -o root -g root -m 0700 "$config_dir"
install -d -o root -g root -m 0755 "$service_dir" "$service_dir/data"
install -d -o 999 -g 999 -m 0700 "$service_dir/data/postgres"
install -d -o 1000 -g 1000 -m 0750 "$service_dir/cache"

if [[ ! -s "$config_dir/database.env" ]]; then
  umask 077
  printf 'HINDSIGHT_DB_PASSWORD=%s\n' "$(openssl rand -hex 32)" \
    >"$config_dir/database.env"
fi
chmod 0600 "$config_dir/database.env"

if [[ ! -s "$config_dir/backup-age.key" ]]; then
  age-keygen -o "$config_dir/backup-age.key"
  age-keygen -y "$config_dir/backup-age.key" \
    >"$config_dir/backup-age-recipient.txt"
fi
chmod 0600 "$config_dir/backup-age.key"
chmod 0644 "$config_dir/backup-age-recipient.txt"

install -o root -g root -m 0644 \
  "$repo_dir/config/rocky-hindsight/docker-compose.yml" \
  "$service_dir/docker-compose.yml"
install -o root -g root -m 0755 \
  "$repo_dir/scripts/23-rocky-hindsight-runtime-env.sh" \
  /usr/local/sbin/rocky-hindsight-runtime-env
install -o root -g root -m 0755 \
  "$repo_dir/scripts/24-backup-rocky-hindsight.sh" \
  /usr/local/sbin/rocky-hindsight-backup
install -o root -g root -m 0755 \
  "$repo_dir/scripts/25-check-rocky-hindsight.sh" \
  /usr/local/sbin/rocky-hindsight-health
install -o root -g root -m 0644 \
  "$repo_dir/config/rocky-hindsight/rocky-hindsight.service" \
  "$repo_dir/config/rocky-hindsight/rocky-hindsight-backup.service" \
  "$repo_dir/config/rocky-hindsight/rocky-hindsight-backup.timer" \
  "$repo_dir/config/rocky-hindsight/rocky-hindsight-health.service" \
  "$repo_dir/config/rocky-hindsight/rocky-hindsight-health.timer" \
  /etc/systemd/system/

if [[ -d /home/openclaw/.pg0 && ! -e "/home/openclaw/.pg0-retired-$timestamp" ]]; then
  mv /home/openclaw/.pg0 "/home/openclaw/.pg0-retired-$timestamp"
fi

systemctl daemon-reload
systemctl enable --now rocky-hindsight.service
systemctl enable --now rocky-hindsight-backup.timer rocky-hindsight-health.timer
/usr/local/sbin/rocky-hindsight-health
/usr/local/sbin/rocky-hindsight-backup

echo "Fresh Rocky Hindsight database, health checks, and backups are installed."
