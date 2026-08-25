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
gateway_wrapper="${openclaw_home}/bin/openclaw-gateway-discord"
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
  .agents.defaults.videoGenerationModel = {primary: "xai/grok-imagine-video", fallbacks: [], timeoutMs: 600000} |
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
  }) |
  .mcp = (.mcp // {}) |
  .mcp.servers = (.mcp.servers // {}) |
  .mcp.servers.percify = {
    url: "https://api.percify.io/v3/mcp",
    transport: "streamable-http",
    timeout: 90,
    connectTimeout: 20,
    supportsParallelToolCalls: true,
    headers: {Authorization: "Bearer ${PERCIFY_API_KEY}"}
  }
' "${config_file}" > "${tmp_config}"

install -o openclaw -g openclaw -m 0600 "${tmp_config}" "${config_file}"
rm -f "${tmp_config}"

[[ -x "${gateway_wrapper}" ]] || { echo "Missing ${gateway_wrapper}" >&2; exit 1; }
if ! grep -q '^export PERCIFY_API_KEY=' "${gateway_wrapper}"; then
  sed -i "/^export DISCORD_BOT_TOKEN=/a export PERCIFY_API_KEY=\"\$(op read 'op://agent-rocky/percify-api-key/credential')\"" "${gateway_wrapper}"
fi
chown openclaw:openclaw "${gateway_wrapper}"
chmod 0755 "${gateway_wrapper}"

# AGENTS.md can exceed OpenClaw's bootstrap limit. Keep this operational rule at
# the top so the model receives it in every new session instead of truncating it.
agent_rules="${workspace}/AGENTS.md"
creative_rule_file="$(mktemp)"
cat > "${creative_rule_file}" <<'EOF'
<!-- manus:direct-creative-authorization:start -->
## Direct User Authorization And Creative Production

- A direct request from Jack to create, generate, draft, design, record, render, or prepare an internal asset is sufficient authorization to start the work. This includes promo videos, voice-overs, images, ad creative, social drafts, emails, documents, presentations, and internal marketing assets.
- Creating a draft asset is internal production, not external publishing. Do not ask Jack for a second approval before starting a directly requested draft. Do not reinterpret a request for a promo video or voice-over as a request to publish it.
- Confirmation is required only immediately before an external or irreversible action: sending to a recipient, posting or publishing publicly, spending funds, changing a live production system, or deleting data. State that boundary only when the next requested step actually crosses it.
- If a requested creative-production capability is unavailable, say exactly what is missing and immediately produce the useful available work, such as the concept, script, storyboard, shot list, voice-over copy, asset list, or production plan. Never refuse a user-authorized draft merely because it could later be used externally.
<!-- manus:direct-creative-authorization:end -->
EOF

media_rule_file="$(mktemp)"
cat > "${media_rule_file}" <<'EOF'
<!-- manus:media-generation-execution:start -->
## Media Generation Execution

- For a direct request to create a video, image, audio asset, or voice-over, invoke the relevant generation tool and submit a real generation request before replying. A provider inventory or capability list is not a completed creative asset.
- If `video_generate` first returns provider information, immediately make a second `video_generate` call with `action: "generate"`, a complete prompt, the configured provider or model, and supported audio, duration, resolution, and aspect-ratio settings. Do not ask for a second approval.
- Use exactly `xai/grok-imagine-video` for xAI video generation. Do not select `xai/wan2.1`, a Wan model, or any other unverified video model. Only fall back to a concept and production package if the verified model returns a concrete failure. Report that exact failure and deliver the usable package in the same reply.
<!-- manus:media-generation-execution:end -->
EOF

percify_rule_file="$(mktemp)"
cat > "${percify_rule_file}" <<'EOF'
<!-- manus:percify-creative-platform:start -->
## Percify Creative Platform

- Percify is a connected MCP capability. Use its tools for direct user-authorized creative production that benefits from a live multi-model catalog, video analysis, video replication, image generation or editing, voice production, talking avatars, dubbing, and multi-clip campaign assets.
- Before a new Percify generation workflow, use `percify__list_models` to select a suitable currently available model. Use `percify__check_usage` when the user asks about credits or when a substantial multi-asset campaign could materially consume account credits. Do not call either tool merely to answer a non-execution question.
- For a user-authorized creative task, invoke Percify’s relevant generation or analysis tool and wait for the result. Do not respond with a provider list, a generic prompt, or a manual workaround while Percify is available.
- Direct requests from Jack authorize internal drafts. Ask for confirmation only immediately before publishing externally, sending to a third party, spending beyond a clearly stated user-approved budget, deleting data, or making another irreversible change.
<!-- manus:percify-creative-platform:end -->
EOF

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
sed '/<!-- manus:direct-creative-authorization:start -->/,/<!-- manus:direct-creative-authorization:end -->/d' "${agent_rules}" | \
  sed '/<!-- manus:media-generation-execution:start -->/,/<!-- manus:media-generation-execution:end -->/d' | \
  sed '/<!-- manus:percify-creative-platform:start -->/,/<!-- manus:percify-creative-platform:end -->/d' | \
  sed '/<!-- manus:screenshot-delivery:start -->/,/<!-- manus:screenshot-delivery:end -->/d' > "${rules_without_marker}"
{ head -n 1 "${rules_without_marker}"; cat "${creative_rule_file}"; cat "${media_rule_file}"; cat "${percify_rule_file}"; cat "${rule_file}"; tail -n +2 "${rules_without_marker}"; } > "${agent_rules}"
chown openclaw:openclaw "${agent_rules}"
chmod 0644 "${agent_rules}"
rm -f "${creative_rule_file}" "${media_rule_file}" "${percify_rule_file}" "${rule_file}" "${rules_without_marker}"

sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user daemon-reload
sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user restart openclaw-gateway.service

printf 'Rocky full capability baseline applied. Backup: %s\n' "${backup_dir}"
