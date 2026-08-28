#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="${repo_dir}/services/asana-http-mcp"
install_dir="/opt/zedbiz/asana-http-mcp"
openclaw_home="/home/openclaw"
runtime_dir="/run/user/$(id -u openclaw)"
config_file="${openclaw_home}/.openclaw/openclaw.json"
gateway_wrapper="${openclaw_home}/bin/openclaw-gateway-discord"
service_wrapper="${openclaw_home}/bin/rocky-asana-http-mcp"
unit_dir="${openclaw_home}/.config/systemd/user"
unit_file="${unit_dir}/rocky-asana-mcp.service"
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S)"
backup_dir="${openclaw_home}/.openclaw/backups/asana-http-mcp-${timestamp}"

[[ -f "${source_dir}/package-lock.json" ]] || { echo "Missing governed Asana source." >&2; exit 1; }
[[ -f "${config_file}" ]] || { echo "Missing ${config_file}." >&2; exit 1; }
[[ -x "${gateway_wrapper}" ]] || { echo "Missing ${gateway_wrapper}." >&2; exit 1; }

install -d -o openclaw -g openclaw -m 0700 "${backup_dir}"
cp -a "${config_file}" "${backup_dir}/openclaw.json"
cp -a "${gateway_wrapper}" "${backup_dir}/openclaw-gateway-discord"
[[ -f "${service_wrapper}" ]] && cp -a "${service_wrapper}" "${backup_dir}/rocky-asana-http-mcp" || true
[[ -f "${unit_file}" ]] && cp -a "${unit_file}" "${backup_dir}/rocky-asana-mcp.service" || true
[[ -x "${openclaw_home}/bin/rocky-asana-mcp" ]] && cp -a "${openclaw_home}/bin/rocky-asana-mcp" "${backup_dir}/rocky-asana-mcp-legacy" || true

install -d -o openclaw -g openclaw -m 0755 "${install_dir}"
find "${install_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
cp -a "${source_dir}/." "${install_dir}/"
chown -R openclaw:openclaw "${install_dir}"

sudo -u openclaw env HOME="${openclaw_home}" npm ci --prefix "${install_dir}"
sudo -u openclaw env HOME="${openclaw_home}" npm run --prefix "${install_dir}" typecheck
sudo -u openclaw env HOME="${openclaw_home}" npm run --prefix "${install_dir}" build
sudo -u openclaw env HOME="${openclaw_home}" npm run --prefix "${install_dir}" test:catalog

cat > "${service_wrapper}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/openclaw
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a
ASANA_ACCESS_TOKEN="$(/home/openclaw/.local/secure-bin/op read 'op://agent-rocky/asana-api-key-rocky/credential')"
export ASANA_ACCESS_TOKEN
export MCP_AUTH_TOKEN="${ASANA_ACCESS_TOKEN}"
export MCP_ALLOWED_HOSTS="127.0.0.1,localhost"
export MCP_BIND_HOST="127.0.0.1"
export MCP_MAX_SESSIONS="64"
export MCP_SESSION_TTL_MS="900000"
export PORT="8080"
exec /usr/bin/node /opt/zedbiz/asana-http-mcp/dist/index.js
EOF
chown openclaw:openclaw "${service_wrapper}"
chmod 0700 "${service_wrapper}"

install -d -o openclaw -g openclaw -m 0755 "${unit_dir}"
cat > "${unit_file}" <<'EOF'
[Unit]
Description=Rocky 76-tool Standard Asana MCP
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/openclaw/bin/rocky-asana-http-mcp
Restart=on-failure
RestartSec=3
MemoryMax=384M
TasksMax=64
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=default.target
EOF
chown openclaw:openclaw "${unit_file}"
chmod 0644 "${unit_file}"

if ! grep -q '^export ASANA_ACCESS_TOKEN=' "${gateway_wrapper}"; then
  sed -i "/^exec \/usr\/bin\/node/i export ASANA_ACCESS_TOKEN=\"\$(op read 'op:\/\/agent-rocky\/asana-api-key-rocky\/credential')\"" "${gateway_wrapper}"
fi
chown openclaw:openclaw "${gateway_wrapper}"
chmod 0755 "${gateway_wrapper}"

tmp_config="$(mktemp)"
jq '
  .mcp = (.mcp // {}) |
  .mcp.servers = (.mcp.servers // {}) |
  .mcp.servers.asana = {
    url: "http://127.0.0.1:8080/mcp",
    transport: "streamable-http",
    supportsParallelToolCalls: true,
    headers: {Authorization: "Bearer ${ASANA_ACCESS_TOKEN}"}
  }
' "${config_file}" > "${tmp_config}"
install -o openclaw -g openclaw -m 0600 "${tmp_config}" "${config_file}"
rm -f "${tmp_config}"

sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" systemctl --user daemon-reload
sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" systemctl --user enable --now rocky-asana-mcp.service

for _ in $(seq 1 30); do
  curl --fail --silent http://127.0.0.1:8080/healthz >/dev/null && break
  sleep 1
done
curl --fail --silent http://127.0.0.1:8080/healthz

asana_pat="$(sudo -u openclaw env HOME="${openclaw_home}" bash -lc "set -a; source '${openclaw_home}/.config/openclaw/1password.env'; set +a; '${openclaw_home}/.local/secure-bin/op' read 'op://agent-rocky/asana-api-key-rocky/credential'")"
sudo -u openclaw env HOME="${openclaw_home}" MCP_AUTH_TOKEN="${asana_pat}" \
  node "${install_dir}/scripts/verify-standard.mjs" \
  "1216804011183079" "rocky@agents.zbiz.ca" "11298561585567"
unset asana_pat

sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  /home/openclaw/.npm-global/bin/openclaw config validate
sudo -u openclaw env HOME="${openclaw_home}" XDG_RUNTIME_DIR="${runtime_dir}" \
  systemctl --user restart openclaw-gateway.service

echo "Rocky's 76-tool Standard Asana HTTP MCP is installed. Backup: ${backup_dir}"
