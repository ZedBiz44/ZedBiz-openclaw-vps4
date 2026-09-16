# Rocky Provider-Based Memory Bank Trial

Date: 2026-09-16 | Agent: Cody | Status: Implemented

## Decision

- Rocky uses one Hindsight memory bank for each communication provider.
- Discord rooms, direct messages, threads, and users share the Discord provider bank.
- OpenClaw Web UI conversations share the Web UI provider bank.
- The approved setting is `dynamicBankId: true` with `dynamicBankGranularity: ["provider"]`.
- Automatic capture and automatic recall remain enabled.

## Reason

- The previous agent, channel, and user combination created more banks than Jack needs.
- Provider-level banks give Rocky broader continuity while keeping Discord and the Web UI separate during this trial.

## Acceptance

- Read back the saved configuration after restart.
- Confirm the Hindsight plugin and API are healthy.
- Complete a real retain-and-recall test through a supported Rocky provider.
- Confirm that a second room on the same provider resolves to the same provider bank.
- Confirm that a different provider resolves to a different bank.

## Review Rule

- Treat this as a trial configuration.
- Review the bank list and cross-channel results before deciding whether to keep provider-based banks or replace them with a different identity rule.

