#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

openclaw_home="/home/openclaw"
openclaw_bin="${openclaw_home}/.npm-global/bin/openclaw"
config_file="${openclaw_home}/.openclaw/openclaw.json"
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S)"
backup_dir="${openclaw_home}/.openclaw/backups/canva-mcp-${timestamp}"

[[ -x "${openclaw_bin}" ]] || { echo "Missing ${openclaw_bin}." >&2; exit 1; }
[[ -f "${config_file}" ]] || { echo "Missing ${config_file}." >&2; exit 1; }

install -d -o openclaw -g openclaw -m 0700 "${backup_dir}"
cp -a "${config_file}" "${backup_dir}/openclaw.json"

sudo -u openclaw env HOME="${openclaw_home}" "${openclaw_bin}" mcp set canva \
  '{"url":"https://mcp.canva.com/mcp","transport":"streamable-http","auth":"oauth","requestTimeoutMs":60000}'

sudo -u openclaw env HOME="${openclaw_home}" "${openclaw_bin}" config validate
sudo -u openclaw env HOME="${openclaw_home}" "${openclaw_bin}" mcp status --verbose

cat <<EOF
Rocky's official Canva MCP route is configured.
Backup: ${backup_dir}

OAuth is intentionally not automated or stored in GitHub. Complete the one-time
operator login as the openclaw user, then verify it:

  sudo -u openclaw env HOME=${openclaw_home} ${openclaw_bin} mcp login canva
  sudo -u openclaw env HOME=${openclaw_home} ${openclaw_bin} mcp doctor canva --probe --json
  sudo -u openclaw env HOME=${openclaw_home} ${openclaw_bin} mcp probe canva --json
EOF
