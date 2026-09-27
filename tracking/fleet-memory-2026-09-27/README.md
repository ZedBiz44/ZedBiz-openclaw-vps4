# Fleet memory retention repair — September 27, 2026

Jack authorized fleet-wide execution and removed the single-agent pilot gate for this repair. Cody owns implementation and verification. Primary record: https://github.com/ZedBiz44/ZedBiz-openclaw-ai-agents-vps1-vps2/issues/254

## Deployed changes

- All 16 AGENTS files retain substantive decisions, reasons, owners, status, next actions, dates and sources. Important corrections and handoffs require explicit save/read-back. Resumption reads the existing daily note and provider history.
- Shared z-record-knowledge skill and memory-layer reference deployed to all 15 OpenClaw agents. Ruby's Hermes proposal `ee74f939` remains staged under its skill-approval queue; her main AGENTS rules are deployed.
- Existing providers, banks, daily files and curated memory remain in use. No new memory system, cross-bank access expansion or transcript bulk import.
- LanceDB routes use runtime owner `main`; business names are not runtime owners. Worker results must return to the main agent for saving in its approved scope.
- Mem0 1.1.0 explicit adds preserve selected facts and source metadata (`infer:false`). The `mem0_search` and `mem0_get` aliases are declared in code and the tool contract. Add responses expose record IDs; explicit search defaults to at least 20 results. Automatic extraction and its configured recall result count remain unchanged.
- Existing Mem0 startup guards call the version-checked repair. Unknown source shapes or versions stop the repair rather than applying an unchecked patch.
- Ruby's curated paths remain `/opt/data/memories/MEMORY.md` and `/opt/data/memories/USER.md`. Her active skill path is explicit because old backup directories produce ambiguous skill-name discovery.

## Live verification

All 16 agents recovered the August 31 ratified business decision and their dated September 25–26 role/work snapshots. Each completed a separate fresh-conversation business recall check. These are agent-owned tool runs. Some Hindsight answers use provider facts plus exact source links from local notes; that distinction remains explicit.

| Provider | Agents | Verified result |
|---|---|---|
| LanceDB | Amanda, Victor, Vivian, Wilma | Explicit save/read-back, fresh repair recall, bounded business recovery and fresh business recall. |
| Mem0 | Edith, Terry, Harry | External tool routing, recovered facts and exact-ID read-back, fresh business recall. |
| Central Hindsight | Marsha, Maggie, Inga, GohZed, Grogar, Frank, Suzy | Recovery and fresh continuity; extracted provider facts distinguished from local exact sources. |
| Rocky Hindsight | Rocky | Recovery and fresh continuity in `rocky-vps4-unknown`; local semantic index remains blocked. |
| Hermes Hindsight | Ruby | Own-client save/read-back and fresh direct Hindsight recall completed; reflect still fails. |

Mem0 receipt proof: Edith's record `8cf1a1a5-eda5-48d1-884b-64d664d60a8f` exposed its ID in the tool response; `mem0_get` returned the same fact and exact issue URL. Earlier full record `dee5746c-9176-477d-af67-4cc36422e594` was readable and searchable but ranked sixth for one query and 22nd for another. A successful write did not guarantee top-five recall.

Ruby document `ruby-cody-memory-recovery-2026-09-27` in `zedbiz-shared` returned HTTP 200, 2,271 characters and both exact source URLs. Her first client call failed before sending with an event-loop error; a subsequent 404 check preceded one successful synchronous retain. No blind write replay.

## Failures found and handled

- Shared skill reference permissions initially prevented part of deployment. The idempotent deployment was rerun through the existing root route and verified, without broad permission changes.
- Mem0 aliases initially lacked manifest declarations; code and manifest are now patched.
- Terry's internal restart retained old plugin code. A full process reload followed a live gateway preflight showing no active work. Subsequent recovery and recall passed.
- Earlier Mem0 extraction omitted facts and provenance. Explicit facts now avoid the second extraction; automatic capture remains on.
- Earlier LanceDB queries used business names instead of owner `main` and returned empty results. Routes were corrected.
- Concurrent tests pressured VPS1 memory. Dispatch concurrency was reduced; running server work finished. Completed clients were closed only after terminal results were collected.
- Ruby encountered transient provider 502s and an xAI stream/read failure. Provider recall later succeeded and recovery completed. Model and credentials were unchanged.
- Rocky's native reindex returned embedding API `429 insufficient_quota / credit_balance_exhausted`. No billing, credentials or provider changed. Direct local reads remain available.

## Remaining limits

- Ruby's shared skill change needs its existing Hermes approval, distinct from deployed AGENTS rules. Her fresh test retrieved the recovery document and exact sources with seven direct recalls; `hindsight_reflect` still returned `Failed to reflect:`. Shared-bank results also mentioned Frank's local check ownership; Ruby correctly retained Cody as fleet owner, but this is not a clean cross-agent attribution benchmark.
- Rocky needs the embedding account funded before native semantic reindex can succeed. His dynamic banks remain separate; CLI proof in `rocky-vps4-unknown` does not establish Discord/cron cross-scope recall.
- Worker-to-main handoff rules are deployed, but every worker/cron/channel combination has not been tested end to end.
- Enabled automatic capture, observed hook activity and explicit saves are separate evidence. This is not a complete automatic-only capture benchmark or next-day retention result.
- Earlier green scores remain historical. No replacement fleet-wide green score is claimed.

## Preservation and rollback

`preservation-register.json` retains baseline, initial candidate and final deployed hashes. Final AGENTS hashes were read back live. Unrelated roles, permissions, models, email handling, journals, publication authority and no-work-cutoff rules were preserved. Existing large files remain below the installed per-file limit without raising it; unrelated requirements were not removed to reach the preferred 16 KB target.

Initial backups are outside workspaces under each state directory's `backups/cody-memory-20260927T181056Z`. Later backup prefixes include `cody-lance-route`, `cody-mem0-route`, `cody-recall-readback`, `cody-recall-length`, `cody-mem0-startup` and `cody-skill-route`. Original ownership/modes were retained. Mem0 original code and manifest have `.before-zedbiz-retention-20260927` copies beside the installed files.

Rollback restores the selected instructions/code/manifest and matching startup guard together, followed by a safe full process reload and read-back. Do not restore unrelated historical timeout behavior or widen bank access.

## Focused code checks

`test-mem0-retention.cjs` runs against the patched installed bundle. It verifies literal facts, source/category metadata, visible saved-record IDs, empty input, subagent restrictions and aliases. The Python transform is idempotent; plugin JavaScript passed `node --check`; all three startup guards passed.

SOPs and prompts remain maintained in Notion. This directory contains technical deployment/evidence records and runtime instruction copies.
