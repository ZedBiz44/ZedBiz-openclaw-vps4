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

## Destination preflight

Before researching a request that includes a write destination, check the exact
user-supplied URL:

```bash
/home/openclaw/bin/rocky-notion-write check <target-url> --source "<requester>"
```

If the target is denied:

- Continue the requested reading, research, summarization, or drafting.
- Do not treat the location restriction as a refusal to do the work.
- Lead the response with the completed work or useful result, not the denial.
- Explain that Rocky cannot write to that location.
- Recommend the best approved destination based on the requester, person,
  project, and current work. Prefer an existing relevant child page; otherwise
  recommend a clearly named working-copy page under the relevant approved root.
- Explain why that destination is the best fit.
- Wait for the user to accept the proposed destination before writing.

Use `shaira`, `john`, `mark`, `paul`, or `jasmin` for work owned by that named
person. Use `va-team` for shared VA, people research, or cross-team work unless
the request context clearly points to a named owner.

## Targeted reading

- For a named record, use Notion search and fetch rather than repeatedly
  querying the full database view.
- Never repeat an identical Notion tool call after it returns successfully.
- Make at most five Notion read calls for one lookup. If the record is still not
  found, report that clearly and ask for a better source link or spelling.
- If a paginated tool cannot accept its returned cursor, stop using that tool
  and switch to search. Never request the first page again.

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

## Controlled working copies

Rocky may read an outside page through MCP but may not edit or duplicate it
through MCP. After the user accepts an approved destination, create a controlled
text working copy:

```bash
/home/openclaw/bin/rocky-notion-write create-copy <approved-parent> \
  "<title>" "<content>" --source-url "<original-url>" \
  --source "<requester>" --approved-by "Jack"
```

This creates a new page under an approved parent and copies readable text. It
does not clone database properties, comments, relations, attachments, embedded
files, permissions, or child pages. State this limitation when exact duplication
matters.

To edit one exact paragraph on an approved page:

```bash
/home/openclaw/bin/rocky-notion-write replace <approved-page> \
  "<exact old text>" "<new text>" --source "<requester>"
```

Use append for additions and replace for one exact paragraph. For a larger
revision, create a fresh controlled working copy containing the revised text.

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
- Never offer broad MCP duplication as a workaround.
- Never write to a suggested alternative until the user accepts it.
- Ask Jack before adding a new write operation or approved target.
- If the helper reports that the target write succeeded but logging failed,
  tell Jack exactly that; do not repeat the target write.
