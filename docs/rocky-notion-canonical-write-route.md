# Rocky Notion Canonical Write Route

Date: 2026-08-25
Author: Cody
Status: Retired

## Historical Record

This document previously made `/home/openclaw/bin/rocky-notion-write` the
canonical write path. That architecture was retired on 2026-08-25.

Rocky's current and only Notion route is the hosted Notion MCP connection using
Rocky's OAuth identity. Governed ZedBiz publication follows
`z-notion-knowledge-publish`. The former helper, internal-token configuration,
local write controls, and backup skill copies were removed.

The old GitHub issues and `Rocky-Notion-Write-Log` remain audit history only.
See `docs/rocky-notion-access.md` for the active model.
