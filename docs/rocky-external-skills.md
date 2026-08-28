# Rocky External Skills

date: 2026-08-28 | agent: Cody | status: Verified

## Scope

This inventory excludes OpenClaw bundled and custodian skills. It lists every
active skill whose live source is `openclaw-extra` or `openclaw-workspace`.
All entries were eligible and model-visible during the live VPS4 verification.

## Enabled OpenClaw Extension Skills

These are external to the bundled base set and are exposed through symlinks in
`/home/openclaw/.openclaw/plugin-skills/`.

| Skill | Live location |
|---|---|
| `browser-automation` | `/home/openclaw/.openclaw/plugin-skills/browser-automation/SKILL.md` |
| `canvas` | `/home/openclaw/.openclaw/plugin-skills/canvas/SKILL.md` |
| `discord` | `/home/openclaw/.openclaw/plugin-skills/discord/SKILL.md` |
| `obsidian-vault-maintainer` | `/home/openclaw/.openclaw/plugin-skills/obsidian-vault-maintainer/SKILL.md` |
| `slack` | `/home/openclaw/.openclaw/plugin-skills/slack/SKILL.md` |
| `wiki-maintainer` | `/home/openclaw/.openclaw/plugin-skills/wiki-maintainer/SKILL.md` |

## ZedBiz Workspace Skills

These are Rocky-specific external skills in
`/home/openclaw/.openclaw/workspace/skills/`.

| Skill | Live location |
|---|---|
| `z-ai-skill-developer` | `/home/openclaw/.openclaw/workspace/skills/z-ai-skill-developer/SKILL.md` |
| `z-audio-production` | `/home/openclaw/.openclaw/workspace/skills/z-audio-production/SKILL.md` |
| `z-knowledge-routing` | `/home/openclaw/.openclaw/workspace/skills/z-knowledge-routing/SKILL.md` |
| `z-notion-knowledge-publish` | `/home/openclaw/.openclaw/workspace/skills/z-notion-knowledge-publish/SKILL.md` |
| `z-record-knowledge` | `/home/openclaw/.openclaw/workspace/skills/z-record-knowledge/SKILL.md` |
| `z-sop-framework` | `/home/openclaw/.openclaw/workspace/skills/z-sop-framework/SKILL.md` |
| `z-video-production` | `/home/openclaw/.openclaw/workspace/skills/z-video-production/SKILL.md` |
| `z-wiki-research` | `/home/openclaw/.openclaw/workspace/skills/z-wiki-research/SKILL.md` |
| `z-asana-agent-control` | `/home/openclaw/.openclaw/workspace/skills/z-asana-agent-control/SKILL.md` |

## Cleanup Verification

- No managed-skill directory exists at `/home/openclaw/.openclaw/skills`.
- No backup, disabled, retired, or failed-upgrade `SKILL.md` remains in the
  discoverable skill tree. Deployment backups remain outside that tree.
- Each workspace skill has exactly one `SKILL.md`.
- `rocky-notion-control`, `website-screenshots`, and
  `z-percify-voice-production` are absent from discovery and the live skill
  tree.
- Nested distribution/example copies of `z-audio-production` and
  `z-sop-framework` were removed from Rocky's live skill tree.
- The legacy `zedbiz-asana-agent-control` folder was removed after the
  canonical `z-asana-agent-control` replacement passed live verification.
