# Rocky Native Channel Feedback

Date: 2026-07-31 | Agent: Cody | Status: Complete

## Purpose

- Give Rocky's users immediate confirmation that an assignment was received.
- Show live progress during longer Slack and Telegram work.
- Use supported OpenClaw v2026.7.1 configuration that survives upgrades.

## Channels

- Slack
- Telegram

## Settings

- `messages.ackReactionScope = "all"`
- `messages.removeAckAfterReply = true`
- Slack acknowledgement: `eyes`
- Telegram acknowledgement: `👀`
- Streaming mode: `progress`
- Progress label: `Working`
- Tool progress: enabled
- Command details: status labels only

## Implementation

- Updated `/home/openclaw/.openclaw/openclaw.json` as the `openclaw` runtime account.
- Backup: `/home/openclaw/.openclaw/openclaw.json.bak-channel-feedback-2026-07-31T171540917Z`
- Validated the configuration before restart.
- Restarted the native `openclaw-gateway.service` through Rocky's systemd user service.

## Verification

- Configuration validation passed.
- Gateway service active after restart.
- Slack returned `running=true` and `probe.ok=true`.
- Telegram returned `running=true` and `probe.ok=true`.

## Rollback

- Restore the dated backup to `/home/openclaw/.openclaw/openclaw.json`.
- Validate the configuration.
- Restart Rocky's `openclaw-gateway.service` as the `openclaw` user.
- Probe Slack and Telegram again.

## Links

- VPS4 build issue: https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/1
- OpenClaw fleet issue: https://github.com/ZedBiz44/ZedBiz-openclaw-ai-agents-vps1-vps2/issues/104
- Notion fleet journal: https://app.notion.com/p/3aea3e33d58181b0820ce7902f7db713
