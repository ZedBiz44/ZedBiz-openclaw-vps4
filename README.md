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
- [Rocky Asana PAT MCP](scripts/12-configure-rocky-asana-mcp.sh)
- [Rocky Asana identity controls](scripts/13-install-rocky-asana-controls.sh)

## Current Status

Rocky's native Gateway, Grok OAuth, OpenRouter fallbacks, 1Password SecretRefs, private VPS1 tunnel, Caddy route, public HTTPS, device pairing, browser chat, shared-wiki sync, email inbox, PAT-backed Asana identity, virtual-assistant profile, and reboot recovery are verified. Rocky is live at [rocky.zbiz.ca](https://rocky.zbiz.ca).
