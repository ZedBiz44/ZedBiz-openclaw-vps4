# ZedBiz OpenClaw VPS4

Technical source of truth for Rocky and all OpenClaw work on ZedBiz VPS4.

## Scope

- One native OpenClaw Gateway on VPS4
- Rocky as the first and only agent during validation
- xAI/Grok OAuth as the primary model route
- OpenRouter models as fallbacks
- HTTPS through the VPS1 Caddy gateway
- Read-only synchronization from the VPS1 shared Memory Wiki

## Security Rules

- Never commit credentials, tokens, private keys, server IPs, or dashboard tokens.
- Keep the OpenClaw Gateway bound to loopback.
- Do not open the Gateway port on the public firewall.
- Keep VPS1 as the authoritative shared Memory Wiki; VPS4 receives a synchronized copy.
- Test one agent and one integration at a time before expanding.

## Build Records

- [Rocky build log](docs/rocky-build-log.md)
- [Official install decision record](docs/official-install-decisions.md)
- [Server bootstrap script](scripts/01-bootstrap.sh)
- [OpenClaw install script](scripts/02-install-openclaw.sh)
- [Rocky onboarding and model policy](scripts/04-onboard-rocky.sh)
- [Private VPS1 links](scripts/07-install-private-links.sh)
- [VPS1 Caddy route](scripts/08-configure-vps1-caddy.sh)
- [1Password-backed OpenRouter setup](scripts/09-configure-1password-openrouter.sh)
- [Rocky identity and operating rules](scripts/10-personalize-rocky.sh)
- [Rocky email client](scripts/11-install-rocky-email.sh)
- [Rocky 76-tool Standard Asana HTTP MCP](scripts/12-configure-rocky-asana-mcp.sh)
- [Rocky `z-asana-agent-control` Skill](scripts/13-install-rocky-asana-controls.sh)
- [Rocky Telegram and Slack channels](scripts/14-configure-rocky-telegram-slack.sh)
- [Rocky ZedBiz wiki skills](scripts/15-install-rocky-wiki-skills.sh)
- [Rocky Hindsight memory](scripts/16-install-rocky-hindsight.sh)
- [Rocky production Hindsight database and backups](scripts/26-install-rocky-hindsight-production.sh)
- [Rocky Hindsight production and backup SOP](docs/rocky-hindsight-production-and-backup-sop.md)
- [Rocky Hindsight production verification](scripts/28-test-rocky-hindsight-production.sh)
- [Rocky Google Workspace gog CLI](scripts/18-install-rocky-gog.sh)
- [Rocky restart API](scripts/20-install-rocky-restart-api.sh)
- [Rocky local FFmpeg and Whisper tools](scripts/21-install-rocky-media-tools.sh)
- [Rocky official Canva MCP](scripts/22-configure-rocky-canva-mcp.sh)
- [Rocky Notion access record](docs/rocky-notion-access.md)

## Current Status

Rocky's native Gateway, Grok OAuth, OpenRouter fallbacks, 1Password SecretRefs, private VPS1 tunnel, Caddy route, public HTTPS, browser device pairing, browser chat, shared-wiki sync, ZedBiz wiki-research skills, Hindsight conversational memory, email inbox, PAT-backed Asana identity, Telegram bot connection and inbound delivery, Slack Socket Mode connection and two-way DM delivery, virtual-assistant profile, restart dashboard integration, and reboot recovery are verified. Hindsight now uses a fresh PostgreSQL database in Docker on VPS4, automatically retains and recalls Rocky's conversations, and contains a traceable baseline loaded from Rocky's `MEMORY.md` and all 758 shared-wiki Markdown pages. Telegram still needs a final human-visible outbound reply confirmation. Outbound email still needs an explicitly approved recipient/message test. Google Drive backup upload still requires the approved Desktop OAuth client and Jack's Google consent; encrypted six-hour local backups are active meanwhile. Rocky is live at [rocky.zbiz.ca](https://rocky.zbiz.ca).

Rocky's Notion access uses one OAuth-backed hosted MCP connection with the full Notion toolset. Governed ZedBiz publication follows the current `z-notion-knowledge-publish` skill; the former internal-token helper and `rocky-notion-control` skill are retired.
- Rocky's local `openai-whisper` skill is Ready without an API key. FFmpeg and the Whisper CLI are reproducibly installed through `scripts/21-install-rocky-media-tools.sh`.
- Rocky's official Canva MCP is OAuth authorized and exposed inside real agent turns. A live `canva__search-designs` call succeeded on 2026-09-01.
