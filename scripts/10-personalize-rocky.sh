#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

source_dir="${1:-/tmp/rocky-workspace-profile}"
workspace="/home/openclaw/.openclaw/workspace"
runtime_dir="/run/user/$(id -u openclaw)"

for file in IDENTITY.md USER.md ROCKY-OPERATING-RULES.md; do
  [[ -f "$source_dir/$file" ]] || { echo "Missing $source_dir/$file" >&2; exit 1; }
  install -o openclaw -g openclaw -m 0644 "$source_dir/$file" "$workspace/$file"
done

if ! grep -Fq 'ROCKY-OPERATING-RULES.md' "$workspace/AGENTS.md"; then
  cat >> "$workspace/AGENTS.md" <<'EOF'

## Rocky's ZedBiz Rules

Read and follow `ROCKY-OPERATING-RULES.md` for Rocky's role, source-of-truth boundaries, safety rules, and communication style.
EOF
fi
chown openclaw:openclaw "$workspace/AGENTS.md"

if [[ -f "$workspace/BOOTSTRAP.md" ]]; then
  mv "$workspace/BOOTSTRAP.md" "$workspace/BOOTSTRAP.completed.md"
  chown openclaw:openclaw "$workspace/BOOTSTRAP.completed.md"
fi

sudo -u openclaw env HOME=/home/openclaw XDG_RUNTIME_DIR="$runtime_dir" \
  /home/openclaw/.npm-global/bin/openclaw agents set-identity \
  --agent main --workspace "$workspace" --from-identity --json

echo "Rocky's identity and virtual-assistant operating rules are active"
