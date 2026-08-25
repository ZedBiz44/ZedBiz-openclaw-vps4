# Rocky Notion Access

date: 2026-08-25 | agent: Cody | status: Active

## Current Access Model

- Rocky uses one Notion connection: hosted Notion MCP authenticated through
  OAuth as the native `openclaw` account.
- The MCP connection has no local tool filter. Rocky receives the complete
  toolset allowed by the connected Notion user, including normal write tools.
- `z-notion-knowledge-publish` is the only governed ZedBiz Notion publishing
  skill. It supplies classification, required-field, duplicate, provenance,
  and read-back rules; it does not narrow Rocky's OAuth permissions.
- User authorization still governs destructive, structural, bulk, and
  permission-changing operations.
- The synchronized Shared Memory Wiki remains read-only. Full Notion OAuth
  access does not change that separate source-of-truth boundary.

## Retired Route

The following July/August 2026 controls are retired and must not be restored as
an active or fallback publishing route:

- `rocky-notion-control`
- `/home/openclaw/bin/rocky-notion-write`
- `/home/openclaw/bin/notion_write.py`
- `/home/openclaw/.config/openclaw/rocky-notion-write.json`
- the `Rocky-Notion-Write-API` internal integration credential
- the read-only Notion MCP include filter

The historical `Rocky-Notion-Write-Log` page and GitHub records remain as audit
history. They are not active infrastructure.

The VPS runtime route is fully retired. The remaining account-side cleanup is
owner-controlled: Rocky's 1Password service account can read but cannot archive
the old item, and the internal Notion integration can be deleted only from an
authenticated Notion integration-management session. The browser automation
session was not signed in, so neither account artifact was falsely reported as
deleted. They must not be treated as a fallback in the meantime.

## Verification Standard

- `openclaw mcp show notion --json` reports OAuth and no `toolFilter`.
- `openclaw mcp probe notion --json` exposes normal Notion write tools with no
  locally filtered tools.
- Rocky completes one harmless publication through OAuth, fetches the exact
  destination, and confirms the new content is visible.
- A fresh Rocky session identifies `z-notion-knowledge-publish` as the governed
  ZedBiz publishing skill and does not mention the retired helper.

## Recovery

If OAuth later expires or fails, reauthorize Rocky's OAuth connection with the
native OpenClaw MCP login flow. Do not silently restore the retired internal
token route; maintaining two live publishing paths recreates the ambiguity this
repair removed.
