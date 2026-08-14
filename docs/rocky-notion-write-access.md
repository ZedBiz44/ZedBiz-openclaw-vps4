# Rocky Notion Write Access Model

Date: 2026-08-14  
Author: Manus  
Status: Active

## Authority Model

**Notion Connections are the sole authority for Rocky’s write access.** The `Rocky-Notion-Write-API` integration can write only to pages and databases connected to it in Notion. No second page allow-list, root alias, or ancestry restriction is maintained on VPS4.

This eliminates configuration drift between Notion’s actual permissions and a duplicate local list. To grant or revoke Rocky write access, add or remove the target page or parent area in the Notion connection settings for `Rocky-Notion-Write-API`.

## Controlled Write Route

Rocky uses only:

```bash
/home/openclaw/bin/rocky-notion-write <command> ...
```

The wrapper loads the 1Password-backed integration token and calls the internal helper. The helper preserves the following safeguards:

| Retained control | Behavior |
|---|---|
| Exact target preflight | The helper checks the exact page URL or ID against the Notion write integration. |
| Exact-block verification | Appends, replacements, and relocations verify returned block content before success is reported. |
| Mandatory audit log | Every successful write and failed attempt is recorded in `Rocky-Notion-Write-Log`. |
| Non-bulk safety | No delete, schema change, or mass-update operation is allowed. |
| Explicit approval | `create-copy` and `relocate` still require the explicit Jack-approval parameter. |
| Canonical route guard | A direct invocation of `notion_write.py` automatically re-executes the approved wrapper. |

## Current Helper Configuration

The local configuration contains only the write-log page ID. It does not contain a `pages` access list. The helper asks Notion directly whether Rocky’s integration can access each supplied target.

## Marketing Plans Verification

The `Rocky-Notion-Write-API` integration can see and preflight the live Marketing Plans page:

```text
Page title: Marketing Plans
Page ID: 3bca3e33-d581-801c-bbc6-da45aed9b934
Canonical URL: https://app.notion.com/p/3bca3e33d581801cbbc6da45aed9b934
Result: target_status=allowed
```

The earlier denied target was a different ID:

```text
3bca3e33-d581-8081-8426-c95e6ed952bd
```

Notion returned HTTP 404 for that ID through Rocky’s write integration. The local allow-list was initially a separate problem but is no longer part of the write-access decision.

## Operating Rule

Rocky must pass the exact Notion page URL supplied by Jack to the helper. Rocky reports success only after receiving the relevant `... successful` result and matching `url=` field. If Notion denies an exact target, Rocky must explain that the page is not available to its write connection and request that Jack connect the correct page or parent in Notion.
