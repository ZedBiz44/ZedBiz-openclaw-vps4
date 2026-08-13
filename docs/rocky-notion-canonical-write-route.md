# Rocky Notion Canonical Write Route

Date: 2026-08-13  
Author: Manus  
Status: Active

## Purpose

Rocky reads Notion through the hosted MCP connection and performs controlled writes through a separate, page-ID-governed helper. This document records the required write route and the guardrail that prevents token-loading failures when an agent accidentally invokes the implementation file directly.

## Canonical Write Path

All write-related commands must use:

```bash
/home/openclaw/bin/rocky-notion-write <command> ...
```

The wrapper loads Rocky's 1Password-backed Notion write credential, sets the `ROCKY_NOTION_WRITE_TOKEN` runtime variable, and invokes the internal implementation file. It is the only supported execution path for `access`, `check`, `append`, `create-copy`, `replace`, and `relocate`.

> The raw implementation file, `/home/openclaw/bin/notion_write.py`, is not an agent tool. Agents must not invoke it directly.

## Direct-Call Guardrail

The implementation file now checks for the `ROCKY_NOTION_WRITE_WRAPPER=1` marker. If the marker is absent, it immediately re-executes the canonical wrapper with the original arguments. This preserves existing page-ID controls, approved-root ancestry validation, exact-block verification, and mandatory write logging while preventing a direct invocation from bypassing the 1Password token-loading step.

## Verification

Both routes were verified on VPS4 as the `openclaw` user:

| Invocation | Result |
|---|---|
| `/home/openclaw/bin/rocky-notion-write check va-team` | Allowed target returned, exit code 0 |
| `python3 /home/openclaw/bin/notion_write.py check va-team` | Automatically rerouted through wrapper, allowed target returned, exit code 0 |

No Notion content was created, changed, or deleted during this verification.

## Operational Rule

When a write fails, Rocky must not claim success. Rocky reports success only after the helper returns the relevant success string and matching target URL. A denied or failed write follows the Notion skill's self-diagnosis process before Rocky responds.

## Related Records

- Rocky Notion control skill: `/home/openclaw/.openclaw/workspace/skills/rocky-notion-control/SKILL.md`
- VPS4 workspace commit: `0b975e0`
- GitHub issue: pending final logging for this correction
