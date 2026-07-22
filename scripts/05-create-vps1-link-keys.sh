#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

ssh_dir="/home/openclaw/.ssh"
install -d -o openclaw -g openclaw -m 0700 "$ssh_dir"

create_key() {
  local path="$1"
  local comment="$2"
  if [[ ! -f "$path" ]]; then
    sudo -u openclaw ssh-keygen -q -t ed25519 -N '' -C "$comment" -f "$path"
  fi
  chown openclaw:openclaw "$path" "$path.pub"
  chmod 0600 "$path"
  chmod 0644 "$path.pub"
  ssh-keygen -lf "$path.pub"
}

create_key "$ssh_dir/vps1-caddy-tunnel" "rocky-vps4-caddy-tunnel"
create_key "$ssh_dir/vps1-wiki-rsync" "rocky-vps4-wiki-rsync"

