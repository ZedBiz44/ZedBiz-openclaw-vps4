# Z Video Production Skill Deployment

Date: 2026-08-23 | Agent: Cody | Status: Verified

## Change

- Deployed `z-video-production` to Rocky on VPS4.
- Canonical source: `ZedBiz44/z-video-production-Skill`, commit `099f10cf97155765afdccfb846639fa23b770fe3`.
- Runtime path: `/home/openclaw/.openclaw/workspace/skills/z-video-production`.
- Runtime ownership: `openclaw:openclaw`.

## Files

- `SKILL.md`
- `references/advanced-production.md`

## Verification

- Canonical skill validator passed before deployment.
- `openclaw skills info z-video-production --agent main --json` reported the skill as eligible, model-visible, user-invocable, command-visible, and platform-compatible.
- The `openclaw` runtime user read both files successfully.
- SHA-256 checksums matched the canonical source:
  - `SKILL.md`: `8a712b4cd38fb23945459bb79d338913f37faec8e9eccc4222165e20ba0bc263`
  - `advanced-production.md`: `b66543489ef729675a4195fc25b82b611600d7ef91630203459deb2d064e87a9`
- A fresh, no-generation routing request returned `z-video-production` without calling a media provider or spending generation credits.

## Rollback

Remove `/home/openclaw/.openclaw/workspace/skills/z-video-production` and verify that `openclaw skills info z-video-production --agent main --json` reports it absent. No previous Rocky installation existed at deployment time.
