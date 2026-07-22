#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  rm -f /etc/sudoers.d/90-openclaw-installer
}
trap cleanup EXIT

printf 'openclaw ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/90-openclaw-installer
chmod 0440 /etc/sudoers.d/90-openclaw-installer
visudo -cf /etc/sudoers.d/90-openclaw-installer

sudo -iu openclaw bash -lc \
  'curl -fsSL --proto "=https" --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard'

sudo -iu openclaw bash -lc 'command -v openclaw && openclaw --version && node --version && npm --version'

echo "OpenClaw installation complete; temporary installer privileges removed"
