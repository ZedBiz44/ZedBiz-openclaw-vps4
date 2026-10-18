# Rocky component maintenance — 2026-10-18

Jack authorized Hindsight, host and tool maintenance after the core OpenClaw update. Operational SOPs and prompts remain maintained in Notion; this record covers implementation and live evidence.

- Ubuntu packages updated, including Node 24.22.0 and 1Password CLI 2.41.0. Docker 29.1.3 and containerd 2.2.1 are the current candidates from this host's Ubuntu package source; no switch to Docker CE was made.
- Hindsight API 1.0.0 pinned to digest `a88678c038b0e4340822b02a5efc566c56d8176b5bffa731bc433fd37f978e4c`; PostgreSQL image and safe-write settings preserved. Official OpenClaw plugin 1.0.0 installed with an exact pin.
- Codex app-server 0.163.0 activated through its explicit command path. summarize 0.25.2, mcporter 0.15.0 and GOG 0.45.0 deployed. GOG's protected keyring loader and Gmail no-send guard remain intact; a real Drive read passed.
- Asana SDK 1.32.1, Express 5.3.0 and jsdom 30.1.3 updated with the existing custom service preserved. Typecheck, build, catalog test and production dependency audit passed (zero reported vulnerabilities).

## Recovery and acceptance

Protected evidence: `/var/backups/rocky-components-20261018`. A full matched runtime/state backup passed four SQLite integrity checks, encryption/decryption checksum validation and private off-host Drive size/MD5 verification. Database export also copied off-host with matching SHA-256. Restore rehearsal against Hindsight 1.0 passed old-memory recall, new write/read and persistence.

Real agent tests proved automatic recall from `rocky-vps4-discord`, automatic capture of accurate maintenance facts, and recall of those facts in a fresh session after Gateway restart. Provider-separated banks and configuration were preserved. Operator tests omitted external delivery and supplied an explicitly synthetic maintenance sender. Tests missing channel/sender context correctly skipped memory; these were test-context failures, not data loss.

Final agent calls used GPT-6.1-Sol with no fallback, fetched the Notion SOP, checked installed tools and returned Rocky's own Asana identity (`1216804011183079`). All eight schedule definitions and integration routes remained unchanged. Receipt: `components-acceptance.json`.

## Failures and limits

The Asana deployment initially inherited restrictive staging permissions on dependency files. The non-root service could not read `undici` and restarted. Restored read/traverse permissions only on deployed program trees and package manifests; credential files were untouched. The service then stayed active and the native agent identity call passed. Preserve this failure in the maintenance record.

OpenClaw reports `provenance-invalid` for the Hindsight npm install, as it did before this update. Official reinstall did not clear it. Automatic hooks are proven; trusted native memory capabilities are not claimed. No trust database bypass or broadened bank access was performed.

The earlier CLI-only Asana attempt used mcporter, which is separate from OpenClaw's native MCP configuration. The authoritative connectivity proof is the successful native `asana.asana_get_user` call after the permission repair.
