#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

log_page_id="${1:-}"
if [[ -z "$log_page_id" ]]; then
  echo "Usage: $0 ROCKY_NOTION_WRITE_LOG_PAGE_ID [staged-source-dir]" >&2
  exit 1
fi

staged_dir="${2:-/tmp/rocky-notion}"
openclaw_home="/home/openclaw"
workspace="$openclaw_home/.openclaw/workspace"
skill_target="$workspace/skills/rocky-notion-control"
config_dir="$openclaw_home/.config/openclaw"
config_file="$config_dir/rocky-notion-write.json"
python_target="$openclaw_home/bin/notion_write.py"
wrapper="$openclaw_home/bin/rocky-notion-write"
openclaw_bin="$openclaw_home/.npm-global/bin/openclaw"
runtime_dir="/run/user/$(id -u openclaw)"

[[ -f "$staged_dir/notion_write.py" ]] || {
  echo "Missing staged notion_write.py" >&2
  exit 1
}
[[ -f "$staged_dir/SKILL.md" ]] || {
  echo "Missing staged Notion skill" >&2
  exit 1
}

install -d -o openclaw -g openclaw -m 0755 "$openclaw_home/bin"
install -d -o openclaw -g openclaw -m 0700 "$config_dir"
install -d -o openclaw -g openclaw -m 0755 "$skill_target"
install -o openclaw -g openclaw -m 0700 "$staged_dir/notion_write.py" "$python_target"
install -o openclaw -g openclaw -m 0644 "$staged_dir/SKILL.md" "$skill_target/SKILL.md"

cat > "$config_file" <<EOF
{
  "log_page_id": "$log_page_id",
  "pages": {
    "shaira": {
      "title": "Shaira-Notion-Edits",
      "id": "3a7a3e33-d581-8065-9884-c911e1967ac3"
    },
    "john": {
      "title": "John-Notion-Edits",
      "id": "3a7a3e33-d581-8052-a577-d727e17fea9a"
    },
    "mark": {
      "title": "Mark-Notion-Edits",
      "id": "3a7a3e33-d581-800d-aed4-fb837903b260"
    },
    "paul": {
      "title": "Paul-Notion-Edits",
      "id": "3a7a3e33-d581-80a5-87c1-f0a72c1c9f23"
    },
    "jasmin": {
      "title": "Jasmin-Notion-Edits",
      "id": "3a7a3e33-d581-8035-9510-f4940b3e7f04"
    },
    "va-team": {
      "title": "VA-Team-Notion-Edits",
      "id": "3a7a3e33-d581-80e9-a8bf-f983b1eec73b"
    }
  }
}
EOF
chown openclaw:openclaw "$config_file"
chmod 0600 "$config_file"

cat > "$wrapper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/openclaw
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/openclaw/1password.env
set +a
ROCKY_NOTION_WRITE_TOKEN="$(
  /home/openclaw/.local/secure-bin/op read \
    'op://agent-rocky/notion-api-key-Rocky/credential'
)"
export ROCKY_NOTION_WRITE_TOKEN
exec /usr/bin/python3 /home/openclaw/bin/notion_write.py "$@"
EOF
chown openclaw:openclaw "$wrapper"
chmod 0700 "$wrapper"

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_bin" mcp set notion \
  '{"url":"https://mcp.notion.com/mcp","transport":"streamable-http","auth":"oauth"}'

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_bin" mcp tools notion --include \
  'notion-download-attachment,notion-fetch,notion-get-comments,notion-get-teams,notion-get-users,notion-query-data-sources,notion-query-meeting-notes,notion-search,resources_list,resources_read'

python3 - "$workspace/AGENTS.md" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
section = """## Rocky Notion Access

- Before Notion work, follow `skills/rocky-notion-control/SKILL.md`.
- Read through the OpenClaw MCP server named `notion`.
- Never write through Notion MCP.
- Write only through `/home/openclaw/bin/rocky-notion-write`.
- Preflight every user-supplied write URL with the helper's `check` action
  before researching.
- If a target is denied, continue the research, explain only the write-location
  boundary, recommend the best approved alternative for the person/project,
  and wait for acceptance before writing.
- Lead with the completed research or draft, not the location restriction.
- Use targeted Notion search/fetch for named records. Never repeat an identical
  successful Notion read call, and stop after five read calls.
- The write helper permits approved root pages and every descendant page inside
  those six approved trees. Child pages do not require separate approval.
- When Jack supplies a Notion page URL, that exact page is the required write
  target. Pass the URL unchanged; never substitute a root alias.
- Rocky may relocate an exact paragraph within the same approved tree only
  through the helper's `relocate` action and only after Jack explicitly asks.
- Rocky may create a controlled text working copy under an approved page only
  after Jack accepts that destination. Never duplicate through broad MCP.
- Every write and relocation requires a matching write-log entry.
- Never print, export, or request Rocky's Notion API token.
"""
pattern = re.compile(r"(?ms)^## Rocky Notion Access\n.*?(?=^## |\Z)")
if pattern.search(text):
    text = pattern.sub(section.rstrip() + "\n\n", text)
else:
    text = text.rstrip() + "\n\n" + section
path.write_text(text, encoding="utf-8")
PY

python3 - "$workspace/TOOLS.md" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
section = """## Rocky Notion Tools

- Read route: OpenClaw MCP server `notion`, filtered to read-only tools.
- Write route: `/home/openclaw/bin/rocky-notion-write`.
- Authentication: Rocky-specific internal integration token resolved from the `agent-rocky` 1Password vault at runtime.
- Write boundary: six approved VA edit pages plus mandatory `Rocky-Notion-Write-Log`.
- Current helper operations: access verification, destination preflight,
  single-page append, exact-paragraph replace, controlled text working-copy
  creation, and same-tree relocation.
"""
pattern = re.compile(r"(?ms)^## Rocky Notion Tools\n.*?(?=^## |\Z)")
if pattern.search(text):
    text = pattern.sub(section.rstrip() + "\n\n", text)
else:
    text = text.rstrip() + "\n\n" + section
path.write_text(text, encoding="utf-8")
PY

chown -R openclaw:openclaw "$skill_target"
chown openclaw:openclaw "$workspace/AGENTS.md" "$workspace/TOOLS.md"

sudo -u openclaw test -x "$wrapper"
sudo -u openclaw test -r "$skill_target/SKILL.md"
sudo -u openclaw /usr/bin/python3 -m py_compile "$python_target"
grep -Fq "$log_page_id" "$config_file"
sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  "$openclaw_bin" mcp show notion --json | jq -e \
  '.auth == "oauth" and (.toolFilter.include | index("notion-fetch")) != null' >/dev/null

echo "Rocky's narrow, logged Notion write route is installed"
