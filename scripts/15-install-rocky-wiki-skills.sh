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

chown openclaw:openclaw "$workspace/AGENTS.md"

sudo -u openclaw env \
  HOME="$openclaw_home" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_bin" skills list | grep -E \
  'zedbiz-knowledge-routing|zedbiz-wiki-research'

test -r "$workspace/shared-memory-wiki/index.md"
grep -Fq '# Wiki Index' "$workspace/shared-memory-wiki/index.md"

echo "Rocky's ZedBiz knowledge-routing and wiki-research skills are installed."
