# Rocky Notion Access

date: 2026-07-24 | agent: Cody | status: Complete

## Access Model

- Broad Notion reading uses the hosted Notion MCP server through OAuth.
- OpenClaw filters the MCP server to read-only tools.
- Controlled writing uses Rocky's internal Notion integration token.
- The write token is resolved from 1Password at runtime and is never stored in GitHub or `openclaw.json`.
- Writes are limited by both Notion page sharing and Rocky's local page-ID allowlist.
- Every supported write must also append a record to `Rocky-Notion-Write-Log`.

## Native OpenClaw MCP

- Runtime account: `openclaw`
- MCP server name: `notion`
- Endpoint: `https://mcp.notion.com/mcp`
- Transport: `streamable-http`
- Authentication: OAuth
- Config path: `/home/openclaw/.openclaw/openclaw.json`
- OAuth credentials: OpenClaw's MCP credential store under the `openclaw` account

Read-only MCP tool filter:

- `notion-download-attachment`
- `notion-fetch`
- `notion-get-comments`
- `notion-get-teams`
- `notion-get-users`
- `notion-query-data-sources`
- `notion-query-database-view`
- `notion-query-meeting-notes`
- `notion-search`
- `resources_list`
- `resources_read`

The filter removes all hosted Notion MCP create, update, move, duplicate,
comment-write, database-write, and view-write tools from Rocky's exposed MCP
surface.

## Controlled Write Route

- Command: `/home/openclaw/bin/rocky-notion-write`
- Implementation: `/home/openclaw/bin/notion_write.py`
- Config: `/home/openclaw/.config/openclaw/rocky-notion-write.json`
- Skill: `/home/openclaw/.openclaw/workspace/skills/rocky-notion-control/SKILL.md`
- 1Password vault: `agent-rocky`
- 1Password item: `notion-api-key-Rocky`
- Secret field reference: `op://agent-rocky/notion-api-key-Rocky/credential`

The helper supports access verification and one-page append. An append target
can be an approved root alias or a direct page URL/ID whose parent chain is
inside one of the six approved roots. It does not support deletes, block
removal, page moves, database schema changes, or mass updates.

## Approved Pages

- `shaira`: `Shaira-Notion-Edits` — `3a7a3e33-d581-8065-9884-c911e1967ac3`
- `john`: `John-Notion-Edits` — `3a7a3e33-d581-8052-a577-d727e17fea9a`
- `mark`: `Mark-Notion-Edits` — `3a7a3e33-d581-800d-aed4-fb837903b260`
- `paul`: `Paul-Notion-Edits` — `3a7a3e33-d581-80a5-87c1-f0a72c1c9f23`
- `jasmin`: `Jasmin-Notion-Edits` — `3a7a3e33-d581-8035-9510-f4940b3e7f04`
- `va-team`: `VA-Team-Notion-Edits` — `3a7a3e33-d581-80e9-a8bf-f983b1eec73b`
- Mandatory log: `Rocky-Notion-Write-Log` — `3a8a3e33-d581-8032-a6eb-fb70b7b425bf`

## Verification

- The internal integration authenticated successfully through Rocky's 1Password service account.
- The token's Notion search returned exactly the six approved edit pages plus the write-log page.
- The helper confirmed read access to all seven pages.
- A harmless append to `VA-Team-Notion-Edits` succeeded.
- A matching Mountain Time success record appeared in `Rocky-Notion-Write-Log`.
- Both Notion pages were fetched independently after the write.
- OpenClaw MCP OAuth completed successfully.
- `openclaw mcp doctor notion --probe` returned `notion: ok`.
- OpenClaw reports the `rocky-notion-control` skill as ready and visible to the model.
- A live Grok agent turn used `notion__notion-fetch` and returned `ROCKY_NOTION_READ_OK`.
- The Gateway, Slack, Telegram, Hindsight, and public HTTP surface recovered after restart.

## Recovery

- Pre-change OpenClaw config backups use:
  `/home/openclaw/.openclaw/openclaw.json.before-notion-*`
- Deployment backup:
  `/home/openclaw/.openclaw/backups/notion-20260724T180804-0600`
- Remove the Notion MCP definition with `openclaw mcp unset notion` only if rollback is explicitly approved.
- Restore `AGENTS.md`, `TOOLS.md`, and `openclaw.json` from the deployment backup if the complete Notion rollout must be reversed.

## Direct-Target Incident And Repair

At 18:17 MDT, Rocky was asked to summarize a Notion page into a linked child
page named `summary`. Rocky substituted the fixed `va-team` alias, so the
helper wrote the summary to the `VA-Team-Notion-Edits` parent instead. Rocky
then incorrectly claimed that the linked page had been written.

Verified root cause:

- The original helper accepted aliases only.
- The target `summary` page was a valid child of `VA-Team-Notion-Edits`.
- The helper's old verification fetched the root page but did not verify the
  exact appended block.
- The helper output did not include the actual destination page ID or URL.

Repair:

- Direct Notion page URLs and IDs are now accepted when their parent chain
  reaches one of the six approved roots.
- Targets outside those six trees fail before any write.
- The exact appended block is fetched and compared with the requested text.
- Success output includes the actual title, page ID, URL, and approved root.
- The skill requires Rocky to pass a user-supplied URL unchanged and prohibits
  substituting a root alias.
- Rocky may not claim success unless the returned target matches the requested
  destination.

Data correction:

- The summary was appended and verified on page
  `3a8a3e33-d581-800c-afdf-d0f432bdc48a`.
- The misplaced source paragraph was archived only after target verification.
- The original append, corrected append, and relocation correction are all
  retained in `Rocky-Notion-Write-Log`.

Regression proof:

- An inaccessible out-of-zone page was rejected before a write.
- A fresh Rocky/Grok session stated that it would pass the exact child-page URL
  and would not substitute `va-team`.
- Runtime backup:
  `/home/openclaw/.openclaw/backups/notion-target-fix-20260724T182543-0600`
