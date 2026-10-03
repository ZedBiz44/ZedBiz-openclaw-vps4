# Rocky maintenance verification — October 3, 2026

## Installed and verified

- OpenClaw 2026.9.8 and tracked plugins remain current.
- Codex 0.160.0 remains selected through the documented executable override; GPT-6.1 Sol uses Rocky's existing OAuth account.
- Hindsight service 0.10.2 is digest-pinned. Health, database connection and recall of existing memories passed.
- The encrypted pre-upgrade backup restored 827 documents into a temporary database, matching production. The temporary database was removed.
- Himalaya 2.2.1 official release checksum passed. Migrated configuration preserves TLS and protected command-based credentials. Resolved the sender-name/address environment placeholders for v2 draft compatibility.
- Email authentication, mailbox listing, envelope listing, message read and unsent draft creation passed. No email was sent.
- Workspace Himalaya skill passes both validators and is eligible/model-visible for main. Deployed SKILL.md SHA256: 476c869bd8be278089288b03047ae0897bf5502429d793d12636f34950da7e40.
- Fresh Rocky run 754d9b93-764b-40e5-b56c-2c6fe2e3c601 used gpt-6.1-sol, fallbackUsed=false, rerouted=false, successful bash tool. Rocky read the installed skill and confirmed Himalaya 2.2.1 and IMAP/SMTP OK.
- Final readiness: ready=true, failing=[], eventLoop.degraded=false. Discord, Slack and Telegram connected, no channel errors.
- No pending apt or snap updates, no failed system services, kernel 6.8.0-146 active, no reboot required.

## Cleanup and recovery

Removed six disabled snap revisions, three unreferenced old Docker images, Node24.18/24.20 compile caches and unused kernel6.8.0-138 packages. Preserved current Hindsight and immediate rollback images, live volumes, models and recovery backups.

Compressed full-state.tar from 14,812,631,040 to 7,853,631,023 bytes. The decompressed SHA256 exactly matches the original saved checksum:
6fc0e3b4eb7a5772dad90c4deefdae2a327292e168f6cda3957d43c43002b125

Compressed SHA256:
689fc6d650b5cd18f09df90dca5183b5f2505237532c6451cc1008640080832b

The compressed file is /root/rocky-maint-20261003/full-state.tar.gz; its checksum and receipt are retained. Only the verified equivalent uncompressed copy was removed.

Final filesystem check: 118,805,860,352 bytes available, 43% used. Actual savings include new update/repair artifacts, so do not sum Docker image display sizes.

## Remaining maintenance warning

The Codex saved-data migration warning is unresolved. Online Doctor refused the live Gateway's database ownership. A short offline pass hit its timeout. A longer offline pass completed all67 transcript archives and database checks but stopped advancing at plugin lifecycle checks, repeatedly launching sqlite-source-revision.worker.js. Graceful interruption did not exit it; stopped only its verified process tree and restored the service. Shared state and all three agent SQLite quick checks returned ok. No migration-readiness records or locks were manually rewritten.

Post-upgrade plugin compatibility probes returned no findings, but update status still retains the migration warning and an older missing temporary update-handoff report. These are separate from the successful live runtime tests. Existing custom service-definition differences were preserved.

The previously held z-record-knowledge local guidance and z-video-creative-direction missing-source exception remain. Do not claim every custom skill matches an upstream latest version.

## Records

Technical history and retained diagnostics: issue57.
Version pin and deployed email skill: PR58.
Detailed local receipts: /root/rocky-maint-20261003/final-updates/.
