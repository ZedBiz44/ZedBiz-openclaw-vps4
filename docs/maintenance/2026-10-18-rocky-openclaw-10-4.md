# Rocky VPS4 maintenance — 2026-10-18

Date: 2026-10-18 | Agent: Cody | Status: Verified live; PR awaiting merge

## Outcome

Rocky runs stock OpenClaw 2026.10.4 (383c124) through the existing native openclaw user service on srv1849801. Existing Node 24.21.0, model routes, credentials, private bind, custom services, eight schedules, workspace instructions and 554 custom skill files were preserved. No OS upgrade or reboot; no reboot-required marker.

Hindsight is deliberately pinned to @vectorize-io/hindsight-openclaw@0.13.0. The updater briefly installed 1.0.0 through the previous floating latest specification; the actual agent test detected the removed knowledge tools. Supported plugin install restored 0.13.0 with --pin --force --no-enable, applied in Gateway generation 3. The repeated actual recall test passed. No Hindsight backend/database changes were made.

GOG 0.43.0 now uses its documented launcher again. A raw binary had replaced the launcher, preventing unattended keyring loading and bypassing the existing draft_only guard. The same binary was preserved at a root-owned versioned path. A stub test proved password availability and --gmail-no-send injection without sending mail; an actual Drive metadata read passed without manually supplying the password.

## Recovery evidence

Protected server evidence: /var/backups/rocky-20261018 (mode 0700). Secret-bearing environment and full logs stay private.

- Offline archive covers active OpenClaw state, complete npm prefix, user service definitions and /home/openclaw/bin.
- Archive restored to a non-live directory; current shared database and main, openclaw, mail_reader databases all passed quick_check.
- Plain archive SHA-256: 59092e3d9e840d7baa0e7463d484ec994b32c9111cbfa9d55d89868fffb6b899.
- Ciphertext SHA-256: 76c7a0466eb2a11c7addd5660c0615b8b9d26c81213b0ab013bbb55b013081ef.
- Existing age key used; decrypt stream reproduced the plain archive checksum.
- Off-host encrypted copy: 7,018,879,122 bytes; Drive MD5 and local MD5 both 0a585cbd252f2255c51df59f14a35941; owner-only permissions.
- Private Drive file ID: 1WwcUydKp99SdWaezifjYnrYMjiuC99Sk. Folder ID: 12vc09pa1rdpPJbmKgegEDu9d9Xw0jaEg. No sharing added; key remains separate.
- Recovery archives, restored copy and failed-update evidence retained. Package downgrade alone cannot reverse migrated state.

## Native updater failure and supported recovery

Native run a4950745-bc42-4f0c-b188-9f85845c1141 staged and admitted the target, passed candidate config/plugin/recovery/Gateway startup checks, then failed at package publication: source-rollback-failed / Package publication object changed.

The publication journal remained prepared with no publication receipts. Installed package identity and version remained original; the old 2026.9.8 process stayed healthy. Compared 41,319 installed package files against the restored backup: no content changes. Recent ctime changes existed, but the exact mismatch cause was not proven. No integrity guards, journal identities or recovery records were patched or deleted.

Following the official manual package-manager procedure:
- Verified no active work and the same npm prefix.
- Cleanly stopped the existing user service.
- As openclaw, installed npm install -g openclaw@2026.10.4 --allow-scripts=openclaw in /home/openclaw/.npm-global. Exit 0.
- Ran openclaw update repair --yes --no-restart --json --timeout 600 using the actual runtime environment.
- Repair run 1479d900-aeff-4c97-a21d-0c3a7fd22dcd finished succeeded. Original operation was preserved as superseded-by-manual-install.
- Doctor, plugin convergence, final config convergence and completion cache all completed. Final error-severity Doctor lint: exit 0, no findings.
- Started the existing user service after maintenance ownership ended.

Doctor changed only top-level meta and wizard fields. Exact protected configuration comparison passed. Existing user service/drop-ins were preserved; CLI warnings about custom RestartSec/TimeoutStartSec settings are operator-policy differences, not service failures.

## Live verification

At 11:46 MDT:
- CLI/package and actual Gateway: 2026.10.4.
- Gateway PID 459294, enabled, active/running, Result=success, NRestarts=0.
- Local /healthz, public rocky.zbiz.ca/healthz and Hindsight /health: HTTP 200.
- Loopback-only Gateway listener and authentication preserved.
- VPS1 private tunnel, restart API and user Asana MCP service active.
- Discord, Slack, Telegram: running/connected, lastError null.
- Eight schedule definitions identical.
- Actual acceptance run a0e87638-ecfc-4f2f-ae3b-0e0213687a62 used openai/gpt-6.1-sol; rerouted=false.
- Successful tools: agent_knowledge_recall, asana.asana_get_user, notion.notion-fetch, bash, skills_read.
- Recalled existing September 27 memory that Rocky supports Amanda's VA/Asana flow. No Markdown substitute.
- Asana: Rocky Zagent, GID 1216804011183079. Notion: VPS4-OpenClaw-Agent-Creation-SOP.
- gog, himalaya, ffmpeg and gh available.
- Runtime MCP schema lint: ok=true, one selected check, no findings.
- 83 eligible/model-visible skills; five missing requirements are macOS-only skills on Linux. No extra packages installed for those.
- No degraded plugins or secret owners. Hindsight 0.13.0 loaded with its eight knowledge tools; exact install pin confirmed. Plugin diagnostics empty.
- Update status: no newer stable available, last repair succeeded, recoverySets empty.

## Memory assessment

At 11:46 MDT the entire service cgroup used 3,323,879,424 bytes (3.10 GiB), including approximately 803.8 MiB file-backed memory. Anonymous memory was 2249.9 MiB. Gateway PSS was 1796.1 MiB, RSS 1854.7 MiB. Peak service memory was 3,503,267,840 bytes. Host available RAM was 12012 MiB, swap used 30.5 MiB, free root disk 86.7 GiB. All cgroup OOM counters were zero.

Pre-update Gateway RSS was 2,123,382,784 bytes (about 2025 MiB). The post-restart reading is lower, but these are not equal-age/load samples and do not establish a leak fix. Existing MemoryMax=infinity was retained. There is ample host headroom; an arbitrary cap is not an efficiency benchmark. No VPS1/VPS2 Docker memory patch was copied to this native installation.

## Limits and records

Channel connectivity was verified; no external test messages sent. No explicit memory writes, integration mutations or paid generation were tested. Hindsight backend capacity and longer-term memory growth were not benchmarked.

The redundant SCP copy to the local workstation finished during closeout at 7,018,879,122 bytes and passed the same SHA-256 check as the server ciphertext. Automatic approval review had blocked cancellation/deletion; the transfer was left alone and the completed copy is retained as an additional verified recovery archive. The independent private Drive copy also remains verified.

SOPs were edited only in Notion and fetched again: main VPS4 SOP, Phase 5 governance, native updates, component lifecycle and Google/GOG connection summary. Added practical recovery, actual runtime verification, third-party pin checks and GOG launcher preservation. Agent Registry, service and deployment records updated/read back.

- [GitHub change issue](https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/59)
- [VPS4 SOP](https://app.notion.com/p/371a3e33d5818357872d0198ecade27d)
- [Deployment record](https://app.notion.com/p/3fda3e33d581818e9dcbc4613ed5c13b)
- [Daily journal](https://app.notion.com/p/3fda3e33d5818139afb0f6670de372c1)
- [Official manual update procedure](https://docs.openclaw.ai/install/updating/update-methods#alternative-manual-npm-pnpm-or-bun)
- [Hindsight breaking-change notes](https://hindsight.vectorize.io/changelog/integrations/openclaw)
