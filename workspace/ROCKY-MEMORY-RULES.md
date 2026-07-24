# Rocky Knowledge And Memory Rules

## Current Verified Architecture

- Hindsight is Rocky's active external conversational-memory provider. It is third-party provider software hosted locally on VPS4, not third-party cloud storage.
- OpenClaw plugin `hindsight-openclaw` version `0.9.0` owns the memory slot with automatic retain and recall enabled.
- Hindsight's API and PostgreSQL data store run locally on VPS4.
- Its extraction model uses Rocky's protected 1Password-backed OpenRouter SecretRef. Never reveal or retain the secret value.
- Banks are dynamically isolated by agent, channel, and user whenever stable identities are available.
- Ten non-empty historical Rocky sessions were backfilled on 2026-07-24 with zero failures.
- Existing Markdown and SQLite memory remain active as additional layers.
- If asked whether Rocky has an external memory provider, answer yes and describe this verified architecture. Do not claim that local workspace files are the only memory system.

## Recall First

- Use Hindsight as the first recall surface before meaningful assignments, research, client work, decisions, handoffs, or continuations.
- Treat recalled information as a lead. Verify current facts against live systems and authoritative records.
- Use explicit Hindsight knowledge tools when automatic recall is insufficient.

## Shared Memory Wiki

- Search `shared-memory-wiki/` when work may depend on reusable ZedBiz knowledge.
- Use `zedbiz-knowledge-routing` to decide where durable information belongs.
- Use `zedbiz-wiki-research` for the approved research and filing process.
- The local `shared-memory-wiki/` folder is read-only and synchronized from VPS1. Never edit it locally.

## Source Of Truth

- GitHub and live configuration are authoritative for VPS4 technical facts.
- The Shared Memory Wiki is authoritative for reviewed AI-readable ZedBiz knowledge.
- Notion is the human operating, planning, review, and SOP layer.
- Hindsight is conversational working memory, not the final source of truth.

## Privacy And Isolation

- Never store credentials, tokens, private keys, recovery details, or secret values in memory.
- Do not deliberately move one VA's private working history into another VA's bank, channel, or response.
- Keep raw transcripts, disposable calculations, temporary troubleshooting chatter, and unverified claims out of durable memory.

## Verification

- Do not claim a memory was saved until the retain operation or bank listing proves it.
- Do not claim recall works until a separate conversation retrieves the expected fact.
- Do not claim wiki access works until a real search returns the expected source-backed page.
