#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
openclaw_home="/home/openclaw"
config_file="${openclaw_home}/.openclaw/openclaw.json"
workspace="${openclaw_home}/.openclaw/workspace"
openclaw_bin="${openclaw_home}/.npm-global/bin/openclaw"
runtime_dir="/run/user/$(id -u openclaw)"
playwright_dir="${openclaw_home}/.local/openclaw-playwright"
playwright_bin="${playwright_dir}/node_modules/.bin/playwright"
managed_browser_dir="${openclaw_home}/.local/share/openclaw-browser"
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S)"
backup_dir="${openclaw_home}/.openclaw/backups/full-capabilities-${timestamp}"

[[ -f "${config_file}" ]] || { echo "Missing ${config_file}" >&2; exit 1; }
[[ -x "${openclaw_bin}" ]] || { echo "Missing ${openclaw_bin}" >&2; exit 1; }

install -d -o openclaw -g openclaw -m 0700 "${backup_dir}"
cp -a "${config_file}" "${backup_dir}/openclaw.json"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y chromium-browser

install -d -o openclaw -g openclaw -m 0755 "${playwright_dir}" "${managed_browser_dir}"
sudo -u openclaw env HOME="${openclaw_home}" npm install --prefix "${playwright_dir}" playwright@1.55.0
"${playwright_bin}" install-deps chromium
sudo -u openclaw env HOME="${openclaw_home}" "${playwright_bin}" install chromium

chrome_path="$(find "${openclaw_home}/.cache/ms-playwright" -type f -path '*/chrome-linux/chrome' -print | sort -V | tail -n 1)"
[[ -n "${chrome_path}" && -x "${chrome_path}" ]] || { echo "Playwright Chromium was not installed." >&2; exit 1; }
ln -sfn "${chrome_path}" "${managed_browser_dir}/chromium"
chown -h openclaw:openclaw "${managed_browser_dir}/chromium"

cat > "${openclaw_home}/bin/openclaw-screenshot" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: openclaw-screenshot <url> <output.png> [height]" >&2
  exit 2
}

url="${1:-}"
output="${2:-}"
height="${3:-1600}"
[[ -n "${url}" && -n "${output}" ]] || usage

browser="/home/openclaw/.local/share/openclaw-browser/chromium"
[[ -x "${browser}" ]] || { echo "Managed Chromium is unavailable." >&2; exit 1; }
mkdir -p "$(dirname "${output}")"
profile_dir="$(mktemp -d /tmp/openclaw-screenshot-XXXXXX)"
trap 'rm -rf "${profile_dir}"' EXIT
"${browser}" --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --hide-scrollbars \
  --window-size="1440,${height}" --virtual-time-budget=8000 \
  --user-data-dir="${profile_dir}" --screenshot="${output}" "${url}"
file "${output}"
EOF
chown openclaw:openclaw "${openclaw_home}/bin/openclaw-screenshot"
chmod 0750 "${openclaw_home}/bin/openclaw-screenshot"

tmp_config="$(mktemp)"
jq --arg browser_path "${managed_browser_dir}/chromium" '
  .tools = ((.tools // {}) + {profile: "full"}) |
  del(.tools.allow, .tools.deny, .tools.sandbox) |
  .plugins = (.plugins // {}) |
  del(.plugins.allow) |
  .plugins.entries = (.plugins.entries // {}) |
  .plugins.entries.browser = ((.plugins.entries.browser // {}) + {enabled: true}) |
  .browser = ((.browser // {}) + {
    enabled: true,
    headless: true,
    defaultProfile: "openclaw",
    executablePath: $browser_path,
    noSandbox: true
  })
' "${config_file}" > "${tmp_config}"

install -o openclaw -g openclaw -m 0600 "${tmp_config}" "${config_file}"
rm -f "${tmp_config}"

install -d -o openclaw -g openclaw -m 0755 "${workspace}/skills/website-screenshots"
install -o openclaw -g openclaw -m 0644 \
  "${repo_dir}/workspace/skills/website-screenshots/SKILL.md" \
  "${workspace}/skills/website-screenshots/SKILL.md"

sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user daemon-reload
sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user restart openclaw-gateway.service

printf 'Rocky full capability baseline applied. Backup: %s\n' "${backup_dir}"
