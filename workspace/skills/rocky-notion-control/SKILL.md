---
name: rocky-notion-control
description: Read ZedBiz Notion through the read-only Rocky MCP tool surface and perform narrowly approved, logged writes through Rocky's internal integration helper.
---

# Rocky Notion Control

## Access lanes

- Read, search, and fetch through the OpenClaw MCP server named `notion`.
- Never use a Notion MCP create, update, delete, move, duplicate, comment, or schema-changing tool.
- Write only through `/home/openclaw/bin/rocky-notion-write`.
- Never call the Notion REST API directly and never retrieve or print the API token.

## Approved writes

The helper currently supports only:

```bash
/home/openclaw/bin/rocky-notion-write append <alias> "<text>" --source "<requester>"
```

Approved aliases:

- `shaira`
- `john`
- `mark`
- `paul`
- `jasmin`
- `va-team`

The helper enforces the page ID allowlist and creates a matching entry in
`Rocky-Notion-Write-Log`. A write is not considered complete unless the log
entry succeeds.

## Safety

- Do not delete pages or blocks.
- Do not change database schemas.
- Do not perform mass or bulk updates.
- Do not write outside the approved aliases.
- Ask Jack before adding a new write operation or approved target.
- If the helper reports that the target write succeeded but logging failed,
  tell Jack exactly that; do not repeat the target write.
