#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

timedatectl set-timezone America/Edmonton
apt-get update
apt-get install -y curl ca-certificates git jq rsync ufw sudo

if ! getent passwd openclaw >/dev/null; then
  useradd --create-home --shell /bin/bash --comment "Rocky OpenClaw runtime" openclaw
fi

loginctl enable-linger openclaw
install -d -o openclaw -g openclaw -m 0755 /var/tmp/openclaw-compile-cache

if ! swapon --show=NAME --noheadings | grep -qx /swapfile; then
  if [[ ! -f /swapfile ]]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
  fi
  swapon /swapfile
fi

grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab

ufw allow OpenSSH
ufw --force enable

echo "VPS4 bootstrap complete"

