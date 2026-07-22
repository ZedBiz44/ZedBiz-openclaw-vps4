# Rocky Build Log

date: 2026-07-22 | agent: Cody | status: In Progress

## Objective

Build Rocky as a single native OpenClaw agent on VPS4, verify it end to end, and document a repeatable human and AI-agent procedure.

## Baseline

- Ubuntu 24.04.4 LTS
- 4 vCPU
- 15 GiB RAM
- 193 GiB root disk
- No OpenClaw, Node.js, Docker, or Caddy installed
- No swap initially configured
- Only SSH listening publicly
- Host timezone initially UTC

## Completed

- Verified SSH access with the dedicated VPS4 key.
- Corrected the local Windows ACL on that private key so OpenSSH would accept it.
- Changed the server timezone to `America/Edmonton`.
- Added a 4 GiB swap file and made it persistent.
- Enabled UFW with inbound SSH allowed and other inbound traffic denied.
- Installed base packages: curl, CA certificates, Git, jq, rsync, UFW, and sudo.
- Created the dedicated `openclaw` runtime account.
- Enabled systemd lingering for the runtime account.
- Created the Node compile-cache directory owned by the runtime account.
- Installed OpenClaw `2026.7.1-2` with the official stable Linux installer under the dedicated `openclaw` account.
- Installed Node.js `24.18.0` and npm `11.16.0` through the supported installer path.
- Completed xAI device-code OAuth and verified a live `xai/grok-4.3` response.
- Installed the Gateway as a persistent systemd user service on loopback port `18789` with token authentication.
- Configured `xai/grok-4.3` as primary and four OpenRouter fallbacks.
- Copied the current 63-model dropdown allowlist from the working VPS1 agents and added direct xAI Grok.
- Installed 1Password CLI and connected Rocky's scoped service account through the official exec SecretRef pattern.
- Kept the OpenRouter API key in 1Password; a live Kimi K2.6 OpenRouter response passed.
- Moved Gateway authentication from plaintext configuration to a protected file SecretRef.
- Created separate restricted SSH keys for the Caddy reverse tunnel and the read-only wiki pull.
- Installed an auto-restarting VPS4-to-VPS1 reverse SSH tunnel. The Gateway port remains private and loopback-only.
- Added the `rocky.zbiz.ca` Caddy route on VPS1 through a host-network bridge bound only to the Caddy Docker gateway.
- Synchronized 582 Shared Memory Wiki files with `rsync -rz --delete --checksum` on a 15-minute systemd timer.
- Verified the complete VPS1 and VPS4 wiki file-tree hashes match.
- Added Rocky's identity, Jack's working profile, and virtual-assistant operating rules.
- Rebooted VPS4 and verified automatic recovery of the Gateway, tunnel, wiki timer, swap, and Mountain Time setting.
- Re-tested Grok, OpenRouter, Gateway health, and the VPS1 Caddy upstream after reboot.

## Current Gate

Create the public DNS record `rocky.zbiz.ca` pointing to the VPS1 Caddy server. After DNS resolves, verify Caddy's public TLS certificate and Rocky's Control UI. Telegram, Slack, email, and Asana remain later one-at-a-time human authorization gates.

## Verified Model Policy

- Primary: `xai/grok-4.3`
- Fallback: `openrouter/anthropic/claude-sonnet-4.6`
- Fallback: `openrouter/google/gemini-3.1-pro-preview`
- Fallback: `openrouter/deepseek/deepseek-v4-pro`
- Fallback: `openrouter/moonshotai/kimi-k2.6`

## Verification Evidence

- Pre-reboot Grok response: `ROCKY_GROK_OK`
- Pre-reboot OpenRouter response: `ROCKY_OPENROUTER_OK`
- Post-reboot Grok response: `ROCKY_REBOOT_GROK_OK`
- Post-reboot OpenRouter response: `ROCKY_REBOOT_OPENROUTER_OK`
- VPS1 Caddy bridge HTTP status: `200`
- Gateway event loop: healthy
- Shared wiki tree hash: matched on both servers
- Secrets audit: no plaintext or unresolved SecretRefs; the expected xAI OAuth profile is reported as legacy OAuth residue because OAuth tokens are outside static SecretRef migration

## Tracking

- GitHub issue: https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/1
- Notion SOP: https://app.notion.com/p/371a3e33d5818357872d0198ecade27d
