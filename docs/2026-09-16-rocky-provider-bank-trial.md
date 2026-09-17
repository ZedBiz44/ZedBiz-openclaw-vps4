# Rocky Provider-Based Memory Banks

Date: 2026-09-16 | Agent: Cody | Status: Accepted and closed

## Final Decision

- Rocky uses one Hindsight memory bank for each communication provider.
- Discord rooms, direct messages, threads, and users share the Discord provider bank.
- OpenClaw Web UI conversations share the Web UI provider bank.
- Other providers use their own provider bank.
- The approved setting is `dynamicBankId: true` with `dynamicBankGranularity: ["provider"]`.
- Automatic capture and automatic recall remain enabled.

## Reason

- The previous agent, channel, and user combination created more active routing divisions than Jack needs.
- Provider-level banks give Rocky continuity across conversations on the same provider while keeping different providers separate.

## Final Acceptance Test

- Live configuration read-back confirmed provider-only routing, automatic capture, and automatic recall.
- A new Discord conversation automatically saved the harmless marker `ROCKY-PROVIDER-CLOSEOUT-MAPLE-7429` into `rocky-vps4-discord`.
- The retain and consolidation operations completed successfully with no error and no retry.
- A fresh independent Discord conversation with a different direct-user identity resolved to the same provider bank and returned the exact marker without calling a memory tool.
- A Slack-provider conversation resolved to `rocky-vps4-slack` and returned `NOT_FOUND` for the Discord marker, proving provider isolation.
- The Slack retain and consolidation operations also completed successfully with no error and no retry.
- The synthetic Discord and Slack test banks were deleted after acceptance. They will be recreated automatically by future real traffic.
- Hindsight remained healthy with PostgreSQL connected after cleanup.

## Preserved Historical Data

- The older `rocky-vps4-unknown` bank was not deleted because it now contains a legitimate Curacao repair record.
- Old failed operations remain as historical audit records; the final provider acceptance operations all passed.
- Older channel/user banks were created by the previous routing policy. They are preserved data, but the live configuration no longer routes new conversations by channel or user.

## Operating Rule

Keep provider-only routing unless a later review finds a practical reason to change it. Verify current facts against live systems, GitHub, the Shared Memory Wiki, and Notion before acting. Provider memory supplies continuity; it does not replace the authoritative record.
