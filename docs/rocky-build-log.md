# Rocky Build Log

date: 2026-07-22 | agent: Cody | status: In Progress

## Objective

Build Rocky as a single native OpenClaw agent on VPS4, verify it end to end, and document a repeatable human and AI-agent procedure.

## Baseline

- Ubuntu 24.04.4 LTS
- 4 vCPU
- 15 GiB RAM
- 193 GiB root disk
- No OpenClaw, Node.js, Docker, or Caddy installed
- No swap initially configured
- Only SSH listening publicly
- Host timezone initially UTC

## Completed

- Verified SSH access with the dedicated VPS4 key.
- Corrected the local Windows ACL on that private key so OpenSSH would accept it.
- Changed the server timezone to `America/Edmonton`.
- Added a 4 GiB swap file and made it persistent.
- Enabled UFW with inbound SSH allowed and other inbound traffic denied.
- Installed base packages: curl, CA certificates, Git, jq, rsync, UFW, and sudo.
- Created the dedicated `openclaw` runtime account.
- Enabled systemd lingering for the runtime account.
- Created the Node compile-cache directory owned by the runtime account.
- Installed OpenClaw `2026.7.1-2` with the official stable Linux installer under the dedicated `openclaw` account.
- Installed Node.js `24.18.0` and npm `11.16.0` through the supported installer path.
- Completed xAI device-code OAuth and verified a live `xai/grok-4.3` response.
- Installed the Gateway as a persistent systemd user service on loopback port `18789` with token authentication.
- Configured `xai/grok-4.3` as primary and four OpenRouter fallbacks.
- Copied the current 63-model dropdown allowlist from the working VPS1 agents and added direct xAI Grok.
- Installed 1Password CLI and connected Rocky's scoped service account through the official exec SecretRef pattern.
- Kept the OpenRouter API key in 1Password; a live Kimi K2.6 OpenRouter response passed.
- Moved Gateway authentication from plaintext configuration to a protected file SecretRef.
- Created separate restricted SSH keys for the Caddy reverse tunnel and the read-only wiki pull.
- Installed an auto-restarting VPS4-to-VPS1 reverse SSH tunnel. The Gateway port remains private and loopback-only.
- Added the `rocky.zbiz.ca` Caddy route on VPS1 through a host-network bridge bound only to the Caddy Docker gateway.
- Synchronized 582 Shared Memory Wiki files with `rsync -rz --delete --checksum` on a 15-minute systemd timer.
- Verified the complete VPS1 and VPS4 wiki file-tree hashes match.
- Added Rocky's identity, Jack's working profile, and virtual-assistant operating rules.
- Rebooted VPS4 and verified automatic recovery of the Gateway, tunnel, wiki timer, swap, and Mountain Time setting.
- Re-tested Grok, OpenRouter, Gateway health, and the VPS1 Caddy upstream after reboot.
- Verified public DNS for `rocky.zbiz.ca` points to VPS1 Caddy.
- Obtained and verified a trusted Let's Encrypt certificate for `rocky.zbiz.ca`.
- Added the narrow VPS1 UFW rule required for Caddy's private Docker subnet to reach only the Rocky bridge port.
- Completed OpenClaw's one-time browser device pairing and verified the authenticated public WebSocket connection.
- Sent a live browser-chat test through the public Control UI and received `ROCKY_PUBLIC_UI_OK` from Grok.
- Rotated the Gateway token after a browser test artifact captured the previous value, removed the artifact, and reconnected successfully with the new token.
- Corrected Rocky's stored email domain in 1Password to the valid `.ca` address and verified an authenticated IMAP login without exposing the password.
- Installed the ZedBiz-standard Himalaya `1.2.0` client natively and verified Rocky can list his inbox with credentials resolved from 1Password at runtime.
- Configured the PAT-backed `@roychri/mcp-server-asana` route as OpenClaw MCP server `asana` without storing the PAT in `openclaw.json`.
- Verified the Asana MCP exposes 41 tools plus resources and prompts.
- Verified the PAT identity as Rocky Zagent, `rocky@agents.zbiz.ca`, user GID `1216804011183079`, in ZedBiz workspace GID `11298561585567`.
- Installed the ZedBiz Asana Agent Control skill and recorded Rocky's exact identity/GID routing rules in `AGENTS.md` and `TOOLS.md`.
- Installed the canonical `zedbiz-knowledge-routing` and `zedbiz-wiki-research` skills and added Rocky's explicit wiki/memory routing rules.
- Verified a live Rocky agent turn found the Meow Apps source in the synchronized Shared Memory Wiki with seven successful tool calls and no write to the read-only copy.
- Installed `@vectorize-io/hindsight-openclaw` `0.9.0` as Rocky's active memory provider with embedded Hindsight API `0.8.5`.
- Installed pinned `uv` `0.11.31` for the local Hindsight runtime and kept the extraction-model credential behind Rocky's existing 1Password OpenRouter SecretRef.
- Configured dynamic memory banks by agent, channel, and user; automatic retain/recall; manual knowledge tools; controlled labels; observations; and consolidation.
- Verified new-chat recall by retaining `CANYON-PINE-7429`, restarting the Gateway, resetting with `/new`, and recalling the code from a different session ID.
- Backfilled all ten non-empty historical Rocky sessions; eleven empty sessions were skipped and zero imports failed.
- Rebooted VPS4 and verified Hindsight, PostgreSQL, Gateway, Slack, Telegram, wiki synchronization, and public HTTPS recovered automatically.

## Current Gate

Slack is complete: Socket Mode, inbound DM events, Grok processing, and outbound Slack replies are verified. Telegram inbound and human-visible outbound DMs are verified. Outbound email is configured but still needs an explicitly approved recipient/message test before it is marked send-verified.

## Verified Model Policy

- Primary: `xai/grok-4.3`
- Fallback: `openrouter/anthropic/claude-sonnet-4.6`
- Fallback: `openrouter/google/gemini-3.1-pro-preview`
- Fallback: `openrouter/deepseek/deepseek-v4-pro`
- Fallback: `openrouter/moonshotai/kimi-k2.6`

## Verification Evidence

- Pre-reboot Grok response: `ROCKY_GROK_OK`
- Pre-reboot OpenRouter response: `ROCKY_OPENROUTER_OK`
- Post-reboot Grok response: `ROCKY_REBOOT_GROK_OK`
- Post-reboot OpenRouter response: `ROCKY_REBOOT_OPENROUTER_OK`
- VPS1 Caddy bridge HTTP status: `200`
- Gateway event loop: healthy
- Shared wiki tree hash: matched on both servers
- Public Control UI: `https://rocky.zbiz.ca` returned HTTP 200 with a trusted certificate
- Public browser/Grok test: `ROCKY_PUBLIC_UI_OK`
- Rocky email credentials: authenticated IMAP login passed
- Himalaya inbox listing: passed
- Asana MCP probe: 41 tools, resources, and prompts with no diagnostics
- Asana PAT identity: Rocky Zagent, user GID `1216804011183079`, workspace GID `11298561585567`
- Telegram and Slack credentials were added to Rocky's 1Password vault. Native channel setup is implemented by `scripts/14-configure-rocky-telegram-slack.sh`.
- Slack Socket Mode probe passed as bot `rocky_slack` in workspace `Zedbiz`; both Slack credential sources reported available.
- Telegram polling probe passed as `@rocky4z_bot`; the bot can join groups but Privacy Mode prevents reading all group messages.
- Explicitly allowlisted the installed Slack plugin and trusted only the loopback reverse-tunnel endpoint for forwarded-client IP handling while retaining Gateway token authentication.
- Secrets audit: no plaintext or unresolved SecretRefs; the expected xAI OAuth profile is reported as legacy OAuth residue because OAuth tokens are outside static SecretRef migration
- Slack App Home initially had its Messages tab in read-only mode. Enabling messages allowed Jack to type to Rocky.
- Slack initially did not forward DMs because the app was missing the `message.im` bot event. Enabling Event Subscriptions with `app_mention` and `message.im` restored inbound delivery.
- Live Slack logs then confirmed three replies delivered to Rocky's direct-message channel on 2026-07-22 MDT.
- Approved a new one-time Control UI browser device request after the Gateway restart and verified the browser was registered as an operator device.
- OpenClaw reports both ZedBiz wiki skills as ready; the live wiki test returned `WIKI_SKILL_OK`.
- Hindsight health returned `{"status":"healthy","database":"connected"}` and the plugin loaded as version `0.9.0`.
- Hindsight's Rocky bank contained 44 facts, 11 observations, no pending operations, and no failed operations after backfill.
- The backfill checkpoint recorded ten completed sessions and zero failed sessions.
- After a full VPS reboot, a new Rocky session again recalled `CANYON-PINE-7429`; public HTTPS returned HTTP 200 with a valid certificate.
- A Telegram self-description test exposed an instruction-loading gap: Rocky's always-loaded `AGENTS.md` only pointed to `ROCKY-MEMORY-RULES.md`, so Grok guessed that local workspace files were the only memory layer even though Hindsight injected context correctly.
- Configured Rocky's native OpenClaw Notion MCP server with OAuth and filtered the exposed surface to read-only tools.
- Installed a Rocky-specific Notion write helper that resolves the internal integration token from 1Password, enforces the six approved VA page IDs, and requires a matching write-log entry.
- Verified token access to exactly the six VA pages and `Rocky-Notion-Write-Log`.
- Completed a harmless append to `VA-Team-Notion-Edits` and independently verified its matching Mountain Time success record.
- Verified a live Rocky/Grok turn used `notion__notion-fetch` and returned `ROCKY_NOTION_READ_OK`.
- Repaired a direct-target routing flaw found by Jack's real Telegram test: Rocky had substituted the `va-team` alias for a linked child page and then falsely claimed the linked page was updated.
- Enhanced the helper to allow direct page URLs/IDs only when their verified ancestor chain reaches an approved root, verify the exact appended block, and report the actual destination ID/URL.
- Relocated the Skill Creation SOP summary into the requested `summary` child page, removed the misplaced parent paragraph after verification, and logged the correction.
- Proved an out-of-zone target fails before writing and a fresh Rocky session preserves the exact supplied child-page URL.
- Repaired the remaining ongoing-session gap after Rocky again substituted the
  `va-team` parent for Jack's linked `Chad` child page.
- Promoted exact child-page routing into Rocky's always-loaded `AGENTS.md` and
  added a narrowly approved, same-tree `relocate` operation.
- Rocky personally relocated the exact Chad Eljisr paragraph in his active
  Telegram session. Independent Notion reads verified the child content, the
  parent cleanup, and the Rocky write-log entry.
- Corrected Notion URL parsing for titled URLs ending in hexadecimal-looking
  characters such as `Chad`; exact `Chad` and `summary` URLs now parse correctly.
- Corrected the gap by placing the verified Hindsight architecture directly in `AGENTS.md`, invalidating only the false retained answer, and seeding the corrected architecture in Jack's isolated Telegram bank.
- Diagnosed Rocky's denied-destination Telegram hang: he repeated the same
  first-page Notion database-view call 44 times, ignored pagination, and never
  reached the write helper.
- Removed the problematic database-view tool from Rocky's exposed Notion MCP
  surface and restarted the Gateway to clear the guarded Telegram lane.
- Added destination preflight, graceful denied-location messaging, relevant
  approved-destination recommendations, explicit acceptance before writing,
  targeted Notion lookup limits, controlled text working copies, and exact
  single-paragraph replacement.
- Verified a fresh Dan Kennedy request completed the research with four tool
  calls, made no unauthorized write, recommended an approved alternative, and
  waited for confirmation.
- Verified Rocky created and edited
  `Rocky-Controlled-Copy-Proof-2026-07-24` under
  `VA-Team-Notion-Edits`; independent Notion reads confirmed the outside `Dan`
  page remained empty and all denial/create/edit audit entries were logged.

## Tracking

- GitHub issue: https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/1

## Google Workspace Through gog

- Rocky uses OpenClaw's bundled `gog` skill and the native Linux `gogcli`
  binary.
- The real `gog` binary is root-owned at
  `/home/openclaw/.local/secure-bin/gog-real`. Rocky uses the protected
  `/home/openclaw/bin/gog` wrapper.
- OAuth refresh tokens use `gog`'s encrypted file-keyring backend. Its randomly
  generated encryption key is readable only by the dedicated `openclaw`
  account.
- Google OAuth is independent of Rocky's xAI/Grok OAuth.
- Full Drive read/write access is enabled only by authorizing the
  `jack@zbiz.work` Google account through `gog`.
- Installation is reproducible through `scripts/18-install-rocky-gog.sh`.
- Notion SOP: https://app.notion.com/p/371a3e33d5818357872d0198ecade27d
## 2026-08-05 Hindsight 0.10.0 And Monthly Memory Benchmark

- Upgraded Rocky's `@vectorize-io/hindsight-openclaw` integration from `0.9.0` to `0.10.0`.
- Preserved the local Hindsight service, dynamic bank prefix `rocky-vps4`, and existing memory data.
- Backup: `/home/openclaw/.openclaw/backups/hindsight-0100-20260805-095236`.
- Verified the OpenClaw gateway active, Hindsight healthy with its database connected, and plugin `0.10.0` loaded.
- Ran the common August memory benchmark. Rocky passed retain, paraphrase, freshness, unsafe-secret, and raw-log checks. The exact synthetic sentinel was not reproduced verbatim and the full Notion URL was not retained verbatim, matching the broader Hindsight pattern.
- Verified the real Rocky user path after upgrade: Rocky recalled `CANYON-PINE-7429` through the OpenClaw agent and Hindsight integration.
- Deleted the synthetic benchmark document after scoring.

## 2026-08-05 Hindsight Green Improvement

- Exposed the supported `agent_knowledge_ingest` tool through Rocky's restricted `coding` tool profile without broadening the rest of his tool access.
- Backed up the live configuration at `/home/openclaw/.openclaw/backups/openclaw-before-hindsight-ingest-20260805-111728.json`.
- Verified Rocky personally ingested and recalled an exact identifier and a complete authoritative Notion URL through his normal Telegram-backed agent session.
- Re-ran the structured exact-value benchmark across all nine Hindsight agents. Every agent returned the exact identifier at rank 1 and the complete source URL at rank 1.
- Recorded the durable operating rule: store exact IDs, URLs, legal or financial figures, and other verbatim values as small atomic Hindsight documents with stable document IDs and source metadata instead of burying them in narrative conversation memory.
- Updated the reproducible installer so future Rocky rebuilds retain access to `agent_knowledge_ingest` while preserving any other explicitly allowed tools.
- Revised Hindsight operating score: **Green — 94/100**.

## 2026-08-19 Local Video Caption Tooling

- Installed FFmpeg and local OpenAI Whisper for Rocky without adding an OpenAI API key.
- Downloaded the Whisper `tiny` model during verification and successfully transcribed a generated audio test file.
- Restarted Rocky's OpenClaw gateway so its cached skill eligibility refreshed.
- Verified `openclaw skills info openai-whisper` reports **Ready** and the gateway remains active.
- Added `scripts/21-install-rocky-media-tools.sh` so the live state is reproducible from GitHub.

## 2026-08-25 Notion OAuth Consolidation And Skill Cleanup

- Retired `rocky-notion-control` and the separate internal-token write helper.
- Removed Rocky's Notion MCP include filter so the OAuth connection exposes the
  complete toolset allowed by Rocky's connected Notion user.
- Made `z-notion-knowledge-publish` Rocky's only governed ZedBiz Notion
  publishing skill.
- Refreshed Rocky's ZedBiz skills from their current canonical GitHub main
  branches and removed skill backup, retired, disabled, and failed-upgrade
  copies from Rocky's host.
- Deployed canonical commits: `z-ai-skill-developer` `9e8941e`,
  `z-audio-production` `e3a94a0`, `z-knowledge-routing` `d81b042`,
  `z-notion-knowledge-publish` `2346997`, `z-record-knowledge` `8661d3f`,
  `z-sop-framework` `5926d33`, `z-video-production` `099f10c`, and
  `z-wiki-research` `2778955`. All eight live `SKILL.md` hashes matched their
  canonical checkout and OpenClaw reported every skill ready.
- Preserved historical GitHub records and `Rocky-Notion-Write-Log` as audit
  history rather than active infrastructure.
- Required a live OAuth write plus exact destination read-back before retiring
  Rocky's 1Password internal-integration credential.
- The OAuth test passed with `notion-update-page` followed by `notion-fetch` on
  `VPS4-OpenClaw-Rocky-Notion-Access`.
- Removed the orphaned `website-screenshots` folder after OpenClaw confirmed it
  was not a discoverable skill. Rocky retains the active OpenClaw extension
  skill `browser-automation` for browser and screenshot work.
- Removed the nested `z-sop-framework` example copy and nested
  `z-audio-production` distribution copy from Rocky's live skill tree so every
  workspace skill has exactly one discoverable `SKILL.md`.
- Removed the stale `z-percify-voice-production` skill. Its former GitHub
  repository now publishes `z-audio-production`, confirming the replacement;
  Rocky retains the current audio skill and Percify MCP capability.
- Refreshed `zedbiz-asana-agent-control` from the current approved ZedBiz copy,
  including the 76-tool Streamable HTTP MCP rules and corrected probe guidance.
- Rocky's 1Password service account returned permission error 101 when asked to
  archive the old item. The Notion management browser required a human login.
  Both account-side artifacts remain owner cleanup; the executable VPS helper,
  config, skill, backups, and active references are removed.

## 2026-08-28 Rocky Asana Standard Route And Governed Skill

- Replaced Rocky's 41-tool raw Asana stdio route with the ZedBiz Standard
  Streamable HTTP service: 76 Asana operations on loopback only.
- Preserved Rocky's existing PAT source,
  `op://agent-rocky/asana-api-key-rocky/credential`; no second Asana account or
  OAuth connection was introduced.
- Installed the canonical `z-asana-agent-control` Skill and removed the legacy
  `zedbiz-asana-agent-control` folder from the live discoverable skill tree.
- Verified the authenticated identity as `rocky@agents.zbiz.ca`, user GID
  `1216804011183079`, in workspace GID `11298561585567`.
- Verified the gateway exposes 80 MCP entries: 76 Asana operations plus four
  prompts/resources, including `asana_get_user`, with zero probe diagnostics.
- Ran a real Rocky read-only agent turn. Rocky loaded the Skill, called the
  current-user tool, reported the correct identity and workspace, and made no
  Asana writes.
- Confirmed `rocky-asana-mcp.service` and `openclaw-gateway.service` active,
  port 8080 bound only to `127.0.0.1`, and `https://rocky.zbiz.ca` returning
  HTTP 200.
- Rollback backups:
  `/home/openclaw/.openclaw/backups/z-asana-agent-control-20260828-005151`
  and `/home/openclaw/.openclaw/backups/asana-http-mcp-20260828-005400`.

## 2026-09-01 Rocky Official Canva MCP

- Added Canva's official remote MCP server at `https://mcp.canva.com/mcp` using
  OpenClaw-managed OAuth and Streamable HTTP.
- Did not use or expose the separate `canva-api-key` client secret in
  1Password; the official MCP route manages its own OAuth client and token
  lifecycle.
- Verified `openclaw mcp status --verbose` reports Canva OAuth authorized and
  `openclaw mcp doctor canva --probe` reports the connection healthy.
- Restarted Rocky's gateway and ran a real isolated Rocky agent turn.
- Rocky successfully called `canva__search-designs` and returned the current
  design IDs for `PF_BrandGuide_V1`, `PF_Icon_JumpingFish`, and
  `PF_Logo_Horizontal_JumpingFish`, with zero tool failures.
- Added `scripts/22-configure-rocky-canva-mcp.sh` and the evergreen Canva
  operating rules so the route and usage boundary are reproducible.
- Live pre-change backup:
  `/home/openclaw/.openclaw/backups/canva-mcp-20260901-01a05e43/openclaw.json`.
