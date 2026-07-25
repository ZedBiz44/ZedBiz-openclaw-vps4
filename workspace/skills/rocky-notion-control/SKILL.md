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
/home/openclaw/bin/rocky-notion-write append <target> "<text>" --source "<requester>"
```

`<target>` can be:

- An approved root alias: `shaira`, `john`, `mark`, `paul`, `jasmin`, or
  `va-team`.
- A Notion page URL or page ID whose parent chain is inside one of those six
  approved roots.

When the user supplies a page URL, pass that exact URL to the helper. Never
replace it with a root alias. The helper validates the page's ancestry,
verifies the exact appended block, and creates a matching entry in
`Rocky-Notion-Write-Log`.

Before reporting success, read the helper's output and report the exact title,
page ID, and URL it returned. Never claim that a requested page was written
unless those values match the requested target.

For an item that Rocky previously appended to the wrong approved page, use the
logged relocate action only after Jack explicitly asks Rocky to move it:

```bash
/home/openclaw/bin/rocky-notion-write relocate <source-page> <target-page> \
  "<exact text>" --source "Jack" --approved-by "Jack"
```

The source and target must be in the same approved root tree. The helper
requires exactly one matching source paragraph, verifies the exact target
paragraph, archives only that matching source block, and logs the relocation.

## Safety

- Do not delete pages. Do not archive blocks except through the approved
  `relocate` action after Jack explicitly asks to move that exact item.
- Do not change database schemas.
- Do not perform mass or bulk updates.
- Do not write outside the six approved root-page trees.
- Fail closed if a direct page cannot be proven to descend from an approved
  root.
- Ask Jack before adding a new write operation or approved target.
- If the helper reports that the target write succeeded but logging failed,
  tell Jack exactly that; do not repeat the target write.
