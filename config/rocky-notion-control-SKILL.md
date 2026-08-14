---
name: rocky-notion-control
description: Rocky Notion read and controlled-write workflow. Notion Connections are the sole authority for write access; the helper verifies every write and logs every attempt.
version: 6.0.0-notion-connections-authoritative
category: productivity
tags: [notion, rocky, openclaw, write-verification, audit]
---
# Rocky Notion Control

## Access authority

Notion Connections are the single source of truth for Rocky's write access.

- Read, search, and fetch through the OpenClaw MCP server named `notion`.
- Never write through Notion MCP.
- Write only through `/home/openclaw/bin/rocky-notion-write`.
- Never call the Notion REST API directly and never retrieve or print the API token.
- If the Rocky-Notion-Write-API integration can access a page in Notion, Rocky may write there through the helper. If Notion denies the integration, Rocky may not write there.
- Do not maintain a second page allow-list, aliases, or local ancestry rules. Grant or remove access through the Rocky-Notion-Write-API connection in Notion.

## Canonical write command

- **Never run** `python3 /home/openclaw/bin/notion_write.py` directly. It is an implementation file, not an agent tool, and bypasses the wrapper that loads Rocky's 1Password-backed write token.
- For every write-related action, including `access`, `check`, `append`, `create-copy`, `replace`, and `relocate`, use only:
  ```bash
  /home/openclaw/bin/rocky-notion-write <command> ...
  ```
- If a raw helper path appears in an error, old session, or example, replace it with the canonical wrapper command before retrying.

## Destination preflight

Before researching a request that includes a write destination, check the exact user-supplied URL:
```bash
/home/openclaw/bin/rocky-notion-write check <target-url> --source "<requester>"
```

- If the helper returns `target_status=allowed`, continue with the requested work and use that exact destination.
- If the helper reports a Notion access error, continue the requested reading, research, summarization, or drafting. Lead with the completed work, then state plainly that the destination is not available to Rocky's Notion write connection.
- Do not guess that a page was deleted or that an ID is wrong if an MCP fetch confirms it exists. Ask Jack to add the page or its parent to the Rocky-Notion-Write-API connection, then retry the exact URL.
- Never substitute a different destination unless Jack explicitly asks for one.

## Targeted reading

- For a named record, use Notion search and fetch rather than repeatedly querying the full database view.
- Never repeat an identical Notion tool call after it returns successfully.
- Make at most five Notion read calls for one lookup. If the record is still not found, report that clearly and ask for a better source link or spelling.
- If a paginated tool cannot accept its returned cursor, stop using that tool and switch to search. Never request the first page again.

## Controlled writes

The helper supports:
```bash
/home/openclaw/bin/rocky-notion-write append <target-url-or-id> "<text>" --source "<requester>"
/home/openclaw/bin/rocky-notion-write create-copy <parent-url-or-id> "<title>" "<content>" --source-url "<original-url>" --source "<requester>" --approved-by "Jack"
/home/openclaw/bin/rocky-notion-write replace <target-url-or-id> "<exact old text>" "<new text>" --source "<requester>"
/home/openclaw/bin/rocky-notion-write relocate <source-url-or-id> <target-url-or-id> "<exact text>" --source "Jack" --approved-by "Jack"
```

- Always pass the exact user-supplied Notion URL to the helper.
- The helper uses the Rocky-Notion-Write-API connection to validate page access, verifies exact changed text, and creates a matching entry in `Rocky-Notion-Write-Log`.
- `create-copy` and `relocate` require explicit Jack approval exactly as shown above.
- For a larger revision, create a fresh controlled working copy containing the revised text rather than making broad edits.

## Success and failure handling

Before reporting success, read the helper's stdout and exit code. The helper exits 0 only on confirmed success. Exit code 2 means failure.

**Never report success unless stdout contains the exact relevant success string (`append successful`, `create-copy successful`, `replace successful`, or `relocate successful`) and a matching `url=` value.**

If the helper exits with code 2 or stdout contains an error message, the write failed. Do not report it as done or say "verified and logged." If MCP can still read the page, explain politely that the destination is not available to Rocky's Notion write connection and ask Jack to grant it in Notion. If MCP cannot read it either, say the page is unavailable and ask for a valid link or access grant.

## Safety

- Do not delete pages.
- Do not archive blocks except through `relocate` after Jack explicitly asks to move that exact item.
- Do not change database schemas.
- Do not perform mass or bulk updates.
- Do not use broad MCP duplication as a workaround.
- Every write and relocation requires a matching write-log entry.
- If the helper reports that the target write succeeded but logging failed, tell Jack exactly that; do not repeat the target write.
