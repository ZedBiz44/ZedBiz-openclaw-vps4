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

## Do Not Do

- Do not run OpenClaw permanently as root.
- Do not mix installer, source checkout, Bun, Docker template, or development-channel methods.
- Do not expose port 18789 publicly.
- Do not use wildcard Control UI origins or disable Gateway security checks.
- Do not copy Hermes or Ruby authentication files into OpenClaw.
- Do not store credentials in GitHub, Notion, logs, or SOP examples.
- Do not run automatic repair commands without reviewing normal diagnostic output first.

