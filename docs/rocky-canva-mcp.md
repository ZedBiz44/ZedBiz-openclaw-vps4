# Rocky Canva MCP

Date: 2026-09-01 | Agent: Cody | Status: Active

## Purpose

- Give Rocky on VPS4 direct Canva access for graphics and video work.
- Use Canva's official remote MCP server instead of a custom Connect API wrapper.
- Keep OAuth tokens in OpenClaw's owner-only state store, never in GitHub, Notion, shell history, or Rocky's JSON config.

## Live Architecture

- Agent: Rocky
- Host: VPS4, native OpenClaw under Linux user `openclaw`
- MCP server: `https://mcp.canva.com/mcp`
- Transport: `streamable-http`
- Authentication: shared operator OAuth for Jack's authorized Canva account
- Request timeout: sixty seconds
- OpenClaw config: `/home/openclaw/.openclaw/openclaw.json`
- OAuth store: `/home/openclaw/.openclaw/state/openclaw.sqlite`

The draft Canva Connect API integration named `Rocky-Canva` is not part of this route. Its client ID and client secret are not required for Rocky's official Canva MCP connection.

## Installation

Run on VPS4 as root:

```bash
./scripts/22-configure-rocky-canva-mcp.sh
```

The script backs up Rocky's OpenClaw config, saves the official Canva MCP definition, validates the config, and prints the OAuth and verification commands.

## OAuth Login

Run the login as `openclaw`. If the browser is on the operator's Windows computer, keep an SSH localhost tunnel open so Canva's callback reaches the login process on VPS4:

```bash
ssh -L 8989:127.0.0.1:8989 root@srv1849801.hstgr.cloud
sudo -u openclaw env HOME=/home/openclaw /home/openclaw/.npm-global/bin/openclaw mcp login canva
```

Open the printed Canva authorization URL in Jack's signed-in Canva browser session and approve access. If the listener expires after approval, use the printed manual `--code` fallback immediately while the PKCE state is still current.

## Verification

```bash
sudo -u openclaw env HOME=/home/openclaw /home/openclaw/.npm-global/bin/openclaw mcp status --verbose
sudo -u openclaw env HOME=/home/openclaw /home/openclaw/.npm-global/bin/openclaw mcp doctor canva --probe --json
sudo -u openclaw env HOME=/home/openclaw /home/openclaw/.npm-global/bin/openclaw mcp probe canva --json
```

Completion requires all of the following:

- Status reports `oauth authorized`.
- Doctor reports `ok: true` with no Canva issues.
- Probe lists Canva's design, editing, asset, folder, brand, comment, export, resize, and video-capable tools.
- A fresh Rocky turn performs a read-only Canva query and returns a real design result.

## Verified Result

- OAuth status: authorized
- Live doctor: passed with no issues
- Live probe: thirty-three Canva tools, no diagnostics
- Fresh Rocky read test: `canva__search-designs` returned
  `PF_BrandGuide_V1`, `PF_Icon_JumpingFish`, and
  `PF_Logo_Horizontal_JumpingFish` with their real design IDs
- No Canva content was created, edited, moved, commented on, exported, or deleted during verification

## Operational Note

Rocky's first `xai/grok-4.6` attempt timed out before its first model event while
loading the combined tool surface, and the configured Claude Sonnet fallback
completed that initial Canva call. A later isolated retest completed directly on
`xai/grok-4.6`, successfully called `canva__search-designs`, and reported zero
tool failures. Canva and Rocky's primary model route are both currently working.
