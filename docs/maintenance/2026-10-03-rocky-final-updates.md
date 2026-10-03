# Rocky maintenance verification — October 3, 2026

## Updates deployed

- OpenClaw 2026.9.8, Node 24.21.0, npm 12.2.0 and Codex 0.160.0. npm is installed under /usr/local without replacing Ubuntu-owned Node files.
- Rocky uses GPT-6.1 Sol through the existing Codex OAuth account and documented app-server executable override. No paid API-key default was introduced.
- Codex, Discord, Slack and Tavily plugins are 2026.9.8; Hindsight plugin is 0.13.0. The other previously inspected installed tools remain current on their supported release lines.
- Hindsight API 0.10.2 is digest-pinned. Health, database connection and recall passed. The encrypted recovery backup restored 827 documents into a temporary database, matching production; that temporary database was removed.
- Himalaya 2.2.1 passed the official checksum, IMAP/SMTP authentication, mailbox/envelope listing, message read and unsent draft composition. No mail was sent or saved. Its workspace compatibility skill passed native and Z AI validation.
- Asana MCP dependencies updated: MCP SDK 1.32.0, Asana 3.3.0, jsdom 30.1.1, esbuild 0.28.2 and TypeScript 7.0.2. Native build/typecheck/catalog checks passed. Full npm audit: zero findings. Candidate and deployed service both passed real account reads with all 76 Standard tools; the 126 Advanced catalog is unchanged.
- Gemini video MCP 0.2.0 retained its server implementation and updated Google GenAI 2.27.0, MCP SDK 1.32.0 and Zod 4.6.5. Full npm audit: zero findings. Both tools discovered and four invalid requests rejected. No paid video request was submitted.
- Updated four outdated Gateway installer defaults: StartLimitBurst=10, StartLimitIntervalSec=300, TimeoutStopSec=330 and KillMode=mixed. Protected 1Password, allocator and deliberate startup/restart drop-ins remain.

## Custom skills resolved

The earlier 23-skill update remains deployed. Both previously held exceptions are now resolved:

- z-video-creative-direction: all six installed files match the verified companion-skill source in ZedBiz44/z-video-production-Skill, normalizing line endings. Native validation passed.
- z-record-knowledge: substantive memory guidance was reconciled with current upstream, preserving Notion ownership of SOPs and prompts. Source PR7 merged at 9881974188be63b90c65cb708e6cf99f9ae55fd9; seven deployed files were compared byte-for-byte and validators/package regression passed.

Live skill canary 6aaa3890-94aa-4637-824d-4fae6758cb8a used exact gpt-6.1-sol through Codex, no fallback/reroute and three successful bash calls.

## Codex migration repair

The saved-data migration is complete. The installed release's noteSessionTranscriptHealth function ran offline through its own maintenance ownership, session integrity and post-session plugin completion gates. It reported:

```
Deferred state migration completed for plugin "codex".
{"complete":true,"warnings":[]}
```

Subsequent update status had no migrationWarnings. The historical recovery script is retained under docs/maintenance/evidence. This was an actual native repair; no migration-ready row or ownership lock was manually rewritten.

The missing temporary managed-update-handoffs SQLite database was initialized with the installed createManagedHandoffLeaseDatabase implementation. Its native ownership, mode and schema checks ran; no synthetic lease record was inserted.

Earlier approaches are retained as failure evidence: full Doctor repeatedly hashed shared state; upstream commit 0eca3d0 and a local scope correction passed 12 focused tests but refused live authority-scope checks. The original regression failed before correction. None of that experimental code remains deployed. Original Doctor hash was verified, all production source links checked, and temporary source/build/dependency trees removed.

## Cleanup and recovery

Removed disabled snap revisions, unused Docker images, obsolete Node compile caches and the unused kernel 6.8.0-138. Kept live volumes, models and immediate rollback images.

Verified compression:
- Full-state backup: 14,812,631,040 to 7,853,631,023 bytes. Original/decompressed SHA256 6fc0e3b4eb7a5772dad90c4deefdae2a327292e168f6cda3957d43c43002b125.
- Older home-runtime backup: 11,258,142,720 to 6,176,809,202 bytes. Original/decompressed SHA256 0f1a33dcc076a77b6f0133994ef5d8f77d40b573ec0d1a2fcef7748bb2e54c74.
- Maintenance recovery archive: 4,595,803,689 bytes, all 8,148 files verified including hard links. SHA256 47197b4abcee69de0a7b26b1a7c6759944a38932eb00bcf37961fd51c425a50e.

Removed duplicate deployed candidates, temporary repair build/source and disposable root pnpm/npm download caches. Unique recovery archives remain. Detailed receipts are under /root/rocky-maint-20261003/final-updates and /root/rocky-maint-20261003/perfection.

## Final live checks

- Final live run 34873334-b657-4cfb-b7bb-07d809f214cc: exact gpt-6.1-sol, Codex harness, profile credentials, no fallback/reroute, four successful tool calls and zero failures. Himalaya 2.2.1, IMAP, SMTP and Hindsight recall all passed.
- Discord, Slack and Telegram: configured, running and connected; lastError=null. No plugin load errors. Gateway ready=true, failing=[], event loop healthy.
- Shared-state and all three current agent SQLite quick checks returned ok. The offline pass also reported each agent integrity gate healthy.
- Refreshed Ubuntu package lists: no pending upgrades. Snaps current; global npm outdated checks empty for /usr/local and Rocky's npm prefix. No failed system services. Kernel 6.8.0-146 active; reboot-required absent.
- Final update status: updateAvailable=false, migrationWarnings=[], packageActivationError absent.
- Disk after final archive retirement: 120,896,282,624 bytes free, 42% used.

## Abandoned updater and backup retirement

The remaining activation error referred to an abandoned prepared 2026.9.8 stage whose predecessor was 2026.9.7. Its phase was prepared, revision 9, with no displaced previous package and no live process references. The working 2026.9.8 installation had a different filesystem identity from both recorded versions. Its original temporary lease database had been removed during the prior reboot; a fresh empty store cannot validate that old identity.

Archived the never-published anchor and control directory only after verifying all 41,321 files and 35 symlinks. Retained archive: abandoned-package-stage.tar.gz, 190,827,866 bytes, SHA256 cafe420d94a4dfbf828b2f6105097e835380dfceec5cba3b0e43ffaba11c7fd0. Removed the obsolete active-location copies; update status then returned no activation error. No historical journal was rewritten to claim completion.

Also archived the two-file September 1 backup for the removed creative-asset-critique identifier after verifying the current z-creative-asset-critique skill. This preserves the old backup without inventing a sole owner for Rocky's shared workspace.

The old pre-migration database snapshot directory was retired after successful native migration and live verification, with no active update. All four files were checksum-verified in retired-pre-migration-databases.tar.gz: 1,414,794,290 bytes, SHA256 788d7d41d2887490f2896ffbf1558eec172c7239bb63b067a67c28b9d000520c.

## Diagnostic limits and intentional settings

Advisory Doctor completed 38 checks (31 optional checks skipped), exit 0. Its report had no error-severity findings. Warnings concerned the deliberate Codex 0.160.0 override, loopback-only Gateway binding for the existing proxy/tunnel topology, and the old database snapshots subsequently archived above. These warnings do not justify reverting the working Sol runtime or exposing the Gateway network port.

The broad mutating doctor --fix command still failed to finish its general plugin lifecycle loop after all 67 archive passes and healthy agent integrity checks. The bounded operator wrapper stopped that process and restored the service; the final live tests and clean update status above were obtained afterward. This upstream diagnostic limitation remains tracked in issue57. Do not claim that full repair command passed or that every optional health check was run.

## Records

- Technical history: https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/57
- Source and sanitized evidence: PR58.
- Daily technical journal: https://www.notion.so/3eea3e33d581814bb8a5faa6ae82ef9e
