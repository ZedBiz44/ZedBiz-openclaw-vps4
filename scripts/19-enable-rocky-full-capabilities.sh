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

# AGENTS.md can exceed OpenClaw's bootstrap limit. Keep this operational rule at
# the top so the model receives it in every new session instead of truncating it.
agent_rules="${workspace}/AGENTS.md"
rule_file="$(mktemp)"
cat > "${rule_file}" <<'EOF'
<!-- manus:screenshot-delivery:start -->
## Browser And Screenshot Delivery

- You have browser, shell execution, file, web search, and web fetch capabilities. Do not describe yourself as limited to `web_fetch` unless a live tool invocation has actually failed.
- For a public website screenshot, **do not call the `browser` screenshot action**. It returns a blank initial-tab PNG on Rocky. You must call `/home/openclaw/bin/openclaw-screenshot` through shell execution, wait for it to finish, and attach that produced PNG before replying.
- Use the managed `browser` tool only for interactive or authenticated pages. Navigate first, then confirm the target page is loaded before requesting a screenshot.
- Store captures under `workspace/artifacts/site-screenshots/` and attach or link the actual image file in the response. Text extraction, HTML, or a written description is never a substitute for a requested screenshot.
- If both screenshot routes fail, report the exact attempted route and the specific failure. Do not replace the requested image with a page summary or ask a follow-up that delays the capture.
<!-- manus:screenshot-delivery:end -->
EOF
rules_without_marker="$(mktemp)"
sed '/<!-- manus:screenshot-delivery:start -->/,/<!-- manus:screenshot-delivery:end -->/d' "${agent_rules}" > "${rules_without_marker}"
{ head -n 1 "${rules_without_marker}"; cat "${rule_file}"; tail -n +2 "${rules_without_marker}"; } > "${agent_rules}"
chown openclaw:openclaw "${agent_rules}"
chmod 0644 "${agent_rules}"
rm -f "${rule_file}" "${rules_without_marker}"

sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user daemon-reload
sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user restart openclaw-gateway.service

printf 'Rocky full capability baseline applied. Backup: %s\n' "${backup_dir}"
