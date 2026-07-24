#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

source_dir="${1:-/tmp/rocky-wiki-skills}"
openclaw_home="/home/openclaw"
workspace="$openclaw_home/.openclaw/workspace"
skills_dir="$workspace/skills"
rules_source="${2:-/tmp/rocky-memory-rules/ROCKY-MEMORY-RULES.md}"
runtime_dir="/run/user/$(id -u openclaw)"
openclaw_bin="$openclaw_home/.npm-global/bin/openclaw"
timestamp="$(date +%Y%m%d-%H%M%S)"

for skill in zedbiz-knowledge-routing zedbiz-wiki-research; do
  skill_file="$source_dir/$skill/SKILL.md"
  [[ -s "$skill_file" ]] || {
    echo "Missing canonical skill file: $skill_file" >&2
    exit 1
  }
done

[[ -s "$rules_source" ]] || {
  echo "Missing Rocky memory rules file: $rules_source" >&2
  exit 1
}

cp -a "$workspace/AGENTS.md" "$workspace/AGENTS.md.before-wiki-skills-$timestamp"

for skill in zedbiz-knowledge-routing zedbiz-wiki-research; do
  install -d -o openclaw -g openclaw -m 0755 "$skills_dir/$skill"
  install -o openclaw -g openclaw -m 0644 \
    "$source_dir/$skill/SKILL.md" "$skills_dir/$skill/SKILL.md"
done

install -o openclaw -g openclaw -m 0644 \
  "$rules_source" "$workspace/ROCKY-MEMORY-RULES.md"

if ! grep -Fq 'ROCKY-MEMORY-RULES.md' "$workspace/AGENTS.md"; then
  cat >>"$workspace/AGENTS.md" <<'EOF'

## Rocky Knowledge And Memory

Read and follow `ROCKY-MEMORY-RULES.md` for shared-wiki research, Hindsight recall, privacy isolation, source-of-truth boundaries, and memory verification.
EOF
fi

if ! grep -Fq 'Hindsight is Rocky'\''s active external conversational-memory provider.' "$workspace/AGENTS.md"; then
  cat >>"$workspace/AGENTS.md" <<'EOF'

### Current Verified Memory Architecture

- Hindsight is Rocky's active external conversational-memory provider. It is third-party provider software hosted locally on VPS4, not a third-party cloud storage service.
- OpenClaw plugin `hindsight-openclaw` version `0.9.0` owns the active memory slot. Automatic retain and recall are enabled.
- Hindsight's API and PostgreSQL store run locally on VPS4. Its extraction model uses Rocky's existing 1Password-backed OpenRouter SecretRef; never reveal or store the secret value.
- Memory banks are dynamically isolated by agent, channel, and user when stable identities are available.
- Rocky's ten non-empty historical OpenClaw sessions were backfilled on 2026-07-24 with zero failures.
- The Shared Memory Wiki is a separate, read-only reviewed-knowledge layer synchronized from VPS1.
- Existing Markdown and SQLite memory remain in place as additional layers.
- If asked whether Rocky has an external memory provider, answer yes and describe this verified architecture. Do not claim that local workspace files are the only memory system.
EOF
fi

chown openclaw:openclaw "$workspace/AGENTS.md"

sudo -u openclaw env \
  HOME="$openclaw_home" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_bin" skills list | grep -E \
  'zedbiz-knowledge-routing|zedbiz-wiki-research'

test -r "$workspace/shared-memory-wiki/index.md"
grep -Fq '# Wiki Index' "$workspace/shared-memory-wiki/index.md"

echo "Rocky's ZedBiz knowledge-routing and wiki-research skills are installed."
