# Rocky local memory search repair

Date: 2026-09-27 MDT. Owner: Cody. Related issue: https://github.com/ZedBiz44/ZedBiz-openclaw-ai-agents-vps1-vps2/issues/254

## Cause and deployed configuration

Native embedding resolution fell back to OAuth profile openai:jzedbiz@gmail.com and returned 429 insufficient_quota / credit_balance_exhausted. Jack's funded API project was not proven empty. Rocky already had service-account access to openclaw-agents-shared/openai-embedding-key. The key's masked ending vv0A matched the dedicated Agent-search-embedding key, and a tiny embeddings request succeeded (HTTP 200, 1536 dimensions).

The adjacent JSON is a merge fragment, not a full configuration replacement. Only the dedicated secret provider and agents.entries.main.memory.search settings were added. It uses the existing protected op executable and secret reference; no key value is recorded. Main chat models and Hindsight configuration are unchanged. Installed OpenClaw 2026.9.5 schema validation passed before atomic deployment. Backup: /home/openclaw/.openclaw/backups/cody-embedding-key-20260927/openclaw.json.before.

## Live verification

- Forced native reindex completed: 93 files, 257 chunks.
- Deep status: embeddingProbe.ok=true; vector.index.state=complete; semanticAvailable=true; indexIdentity.status=valid; searchMode=hybrid; providerState.mode=active.
- Native search returned the August 31 business decision as its top result with exact source URL and a nonzero vector score.
- Fresh Rocky conversation cody-memory-native-embedding-fixed-rocky-75d50aa44b completed successfully. Rocky used native memory_search and memory_get, recovered the decision and rejected service models, and distinguished superseded September 26 wording from corrected September 27 notes.
- No manual gateway restart was performed.

## Limits and earlier corrections

This proves Rocky's local semantic-search route, not all Hindsight channel/bank handoffs or next-day retention. His dynamic banks remain unchanged. Ruby's previously pending skill approval ee74f939 has also completed after a narrow directory ownership repair; her separate hindsight_reflect failure remains. Earlier fleet README entries about needing more credits or Ruby's pending approval are superseded by this record.

Reindex emitted a pre-existing skill-workshop collection-backup ownership warning because main and mail_reader share a workspace. That unrelated warning was not repaired. Local result printing initially hit Windows cp1252 encoding after the successful rebuild; the saved output and deep status confirmed completion.
