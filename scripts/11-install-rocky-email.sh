#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

staged_binary="${1:-/tmp/himalaya}"
staged_config="${2:-/tmp/himalaya-rocky.toml}"
openclaw_home="/home/openclaw"
runtime_dir="/run/user/$(id -u openclaw)"
secure_bin_dir="$openclaw_home/.local/secure-bin"
config_dir="$openclaw_home/.config/himalaya"

[[ -x "$staged_binary" ]] || { echo "Missing executable Himalaya binary: $staged_binary" >&2; exit 1; }
[[ -f "$staged_config" ]] || { echo "Missing Himalaya config: $staged_config" >&2; exit 1; }

install -d -o root -g root -m 0755 "$secure_bin_dir"
install -o root -g root -m 0755 "$staged_binary" "$secure_bin_dir/himalaya-real"
install -d -o openclaw -g openclaw -m 0700 "$config_dir"
install -o openclaw -g openclaw -m 0600 "$staged_config" "$config_dir/config.toml"
install -d -o openclaw -g openclaw -m 0755 "$openclaw_home/bin"

cat > "$openclaw_home/bin/rocky-email-password" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a
exec /home/openclaw/.local/secure-bin/op read 'op://agent-rocky/email-pw-rocky/credential'
EOF

cat > "$openclaw_home/bin/himalaya" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a
EMAIL_ADDRESS="$(/home/openclaw/.local/secure-bin/op read 'op://agent-rocky/email-address-rocky/credential')"
export EMAIL_ADDRESS
exec /home/openclaw/.local/secure-bin/himalaya-real "$@"
EOF

chown openclaw:openclaw "$openclaw_home/bin/rocky-email-password" "$openclaw_home/bin/himalaya"
chmod 0700 "$openclaw_home/bin/rocky-email-password" "$openclaw_home/bin/himalaya"

if ! grep -Fq '## Rocky Email' "$openclaw_home/.openclaw/workspace/TOOLS.md"; then
  cat >> "$openclaw_home/.openclaw/workspace/TOOLS.md" <<'EOF'

## Rocky Email

- Command: `/home/openclaw/bin/himalaya`
- Account: Rocky's isolated `agents.zbiz.ca` mailbox
- Read/list examples: `himalaya envelope list`, `himalaya message read <id>`
- Before sending, confirm the recipient, subject, and final message unless Jack has given standing permission for that exact workflow.
- Credentials resolve from Rocky's 1Password vault at runtime. Never print, log, or copy them.
EOF
  chown openclaw:openclaw "$openclaw_home/.openclaw/workspace/TOOLS.md"
fi

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_home/bin/himalaya" --version
sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_home/bin/himalaya" envelope list --page-size 1 >/dev/null

echo "Rocky's Himalaya email client is installed and IMAP access is verified"
