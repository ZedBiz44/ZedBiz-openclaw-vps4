#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
staged_skill="${1:-${repo_dir}/skills/z-asana-agent-control}"
workspace="/home/openclaw/.openclaw/workspace"
skill_target="${workspace}/skills/z-asana-agent-control"
legacy_target="${workspace}/skills/zedbiz-asana-agent-control"
timestamp="$(TZ=America/Edmonton date +%Y%m%d-%H%M%S)"
backup_dir="/home/openclaw/.openclaw/backups/z-asana-agent-control-${timestamp}"

[[ -f "${staged_skill}/SKILL.md" ]] || { echo "Missing staged Asana skill." >&2; exit 1; }
grep -Fq 'name: z-asana-agent-control' "${staged_skill}/SKILL.md"

install -d -o openclaw -g openclaw -m 0700 "${backup_dir}"
[[ -d "${skill_target}" ]] && cp -a "${skill_target}" "${backup_dir}/z-asana-agent-control" || true
[[ -d "${legacy_target}" ]] && cp -a "${legacy_target}" "${backup_dir}/zedbiz-asana-agent-control" || true
cp -a "${workspace}/AGENTS.md" "${backup_dir}/AGENTS.md"
[[ -f "${workspace}/TOOLS.md" ]] && cp -a "${workspace}/TOOLS.md" "${backup_dir}/TOOLS.md" || true

install -d -o openclaw -g openclaw -m 0755 "${skill_target}/agents"
install -o openclaw -g openclaw -m 0644 "${staged_skill}/SKILL.md" "${skill_target}/SKILL.md"
if [[ -f "${staged_skill}/agents/openai.yaml" ]]; then
  install -o openclaw -g openclaw -m 0644 \
    "${staged_skill}/agents/openai.yaml" "${skill_target}/agents/openai.yaml"
fi

instruction_files=("${workspace}/AGENTS.md")
[[ -f "${workspace}/TOOLS.md" ]] && instruction_files+=("${workspace}/TOOLS.md")
sed -i 's#skills/zedbiz-asana-agent-control/#skills/z-asana-agent-control/#g' "${instruction_files[@]}"
sed -i 's/`zedbiz-asana-agent-control`/`z-asana-agent-control`/g' "${instruction_files[@]}"

if [[ -d "${legacy_target}" ]]; then
  resolved_legacy="$(readlink -f "${legacy_target}")"
  expected_legacy="$(readlink -m "${legacy_target}")"
  [[ "${resolved_legacy}" == "${expected_legacy}" ]] || { echo "Legacy target is not the expected directory." >&2; exit 1; }
  rm -rf -- "${legacy_target}"
fi

chown -R openclaw:openclaw "${skill_target}"
chown openclaw:openclaw "${instruction_files[@]}"
sudo -u openclaw test -r "${skill_target}/SKILL.md"
grep -Fq 'name: z-asana-agent-control' "${skill_target}/SKILL.md"
grep -Fq '1216804011183079' "${workspace}/AGENTS.md"
grep -Fq '11298561585567' "${workspace}/AGENTS.md"

echo "Rocky's z-asana-agent-control Skill is installed. Backup: ${backup_dir}"
