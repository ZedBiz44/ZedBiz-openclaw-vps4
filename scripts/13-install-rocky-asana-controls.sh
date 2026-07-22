#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

staged_skill="${1:-/tmp/zedbiz-asana-agent-control}"
workspace="/home/openclaw/.openclaw/workspace"
skill_target="$workspace/skills/zedbiz-asana-agent-control"

[[ -f "$staged_skill/SKILL.md" ]] || { echo "Missing staged Asana skill" >&2; exit 1; }

install -d -o openclaw -g openclaw -m 0755 "$skill_target/agents"
install -o openclaw -g openclaw -m 0644 "$staged_skill/SKILL.md" "$skill_target/SKILL.md"
if [[ -f "$staged_skill/agents/openai.yaml" ]]; then
  install -o openclaw -g openclaw -m 0644 \
    "$staged_skill/agents/openai.yaml" "$skill_target/agents/openai.yaml"
fi

if ! grep -Fq '## Rocky Asana Identity' "$workspace/AGENTS.md"; then
  cat >> "$workspace/AGENTS.md" <<'EOF'

## Rocky Asana Identity

- Agent name: Rocky
- Asana user name: Rocky Zagent
- Asana email: rocky@agents.zbiz.ca
- Asana user GID: 1216804011183079
- Required ZedBiz workspace GID: 11298561585567
- Required tool route: PAT-backed OpenClaw MCP server named `asana`
- Before any Asana task work, follow `skills/zedbiz-asana-agent-control/SKILL.md` and verify this identity.
- Never use a Jack-authenticated Codex or ChatGPT Asana connector for Rocky's assigned work.
EOF
fi

if ! grep -Fq '## Rocky Asana MCP' "$workspace/TOOLS.md"; then
  cat >> "$workspace/TOOLS.md" <<'EOF'

## Rocky Asana MCP

- Server name: `asana`
- Authentication: Rocky-specific PAT resolved from the `agent-rocky` 1Password vault at runtime
- Asana identity: Rocky Zagent (`rocky@agents.zbiz.ca`)
- User GID: `1216804011183079`
- ZedBiz workspace GID: `11298561585567`
- Verified exposure: 41 tools plus resources and prompts
- Always resolve names to GIDs before task queries or updates.
EOF
fi

chown -R openclaw:openclaw "$skill_target"
chown openclaw:openclaw "$workspace/AGENTS.md" "$workspace/TOOLS.md"

sudo -u openclaw test -r "$skill_target/SKILL.md"
grep -Fq '1216804011183079' "$workspace/AGENTS.md"
grep -Fq '11298561585567' "$workspace/TOOLS.md"

echo "Rocky's Asana skill, identity, and PAT routing controls are installed"
