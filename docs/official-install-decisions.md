# Official OpenClaw Install Decisions

date: 2026-07-22 | agent: Cody | status: Active

## Follow

- Use the official stable Linux installer.
- Use the installer-managed supported Node.js version.
- Run OpenClaw as a dedicated Linux account.
- Use a systemd user service with lingering enabled.
- Keep the Gateway on loopback with token authentication.
- Use exact browser origins when HTTPS routing is added.
- Isolate direct-message sessions for a business or multi-user agent.
- Verify the model, service, health, reboot survival, HTTPS route, and wiki synchronization.

## Change or Delay

- Run installation without onboarding so the xAI device-code step can be handled as a clear human gate.
- Add only one agent and one model route before channels and other integrations.
- Put VPS1 Caddy in front through a private transport; never expose the Gateway port publicly.
- Add the VPS1 shared Memory Wiki only after the base Gateway and model pass live verification.
- Use OpenClaw's documented 1Password exec SecretRef method so OpenRouter credentials resolve in memory rather than being stored in `openclaw.json`.
- Use two separately restricted SSH identities: one permits only the named reverse-forward listener, while the other is forced through read-only `rrsync`.
- Use `rsync -rz` rather than archive mode because ownership preservation is neither required nor permitted for the read-only VPS1 wiki source.
- Keep Caddy on VPS1. A small `socat` bridge exposes the reverse-tunnel listener only to Caddy's Docker gateway, not to the public network.
- Keep the VPS1 Shared Memory Wiki as the reviewed, authoritative agent-knowledge layer and give Rocky read-only access through the canonical ZedBiz routing and research skills.
- Use Hindsight as Rocky's conversational working-memory layer, with automatic retention and recall, while preserving existing Markdown and SQLite memory files.
- Use dynamic Hindsight banks scoped by agent, channel, and user so a stable channel identity does not share conversational recall with another user.
- Run Hindsight locally on VPS4 and resolve its extraction model through Rocky's existing 1Password-backed OpenRouter SecretRef.
- Backfill historical OpenClaw sessions once, record the checkpoint, and verify recall after both a new-session reset and a full server reboot.

## Do Not Do

- Do not run OpenClaw permanently as root.
- Do not mix installer, source checkout, Bun, Docker template, or development-channel methods.
- Do not expose port 18789 publicly.
- Do not use wildcard Control UI origins or disable Gateway security checks.
- Do not copy Hermes or Ruby authentication files into OpenClaw.
- Do not store credentials in GitHub, Notion, logs, or SOP examples.
- Do not run automatic repair commands without reviewing normal diagnostic output first.
