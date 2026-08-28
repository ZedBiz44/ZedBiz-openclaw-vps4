date: 2026-08-28 | agent: Cody | status: Deployed and verified

# Rocky Asana Agent Control Deployment

## Outcome

Rocky now uses the ZedBiz Standard PAT-backed Streamable HTTP Asana service and
the governed `z-asana-agent-control` Skill. The old raw 41-tool stdio route and
legacy Skill folder are no longer active.

## Live Verification

- Rocky identity: `rocky@agents.zbiz.ca`
- User GID: `1216804011183079`
- Workspace GID: `11298561585567`
- Service catalog: 76 Asana operations
- OpenClaw exposure: 80 entries, consisting of 76 operations and four
  prompts/resources
- Required current-user operation: present and successful
- Probe diagnostics: zero
- Real Rocky read-only agent turn: successful with zero tool failures and no
  Asana writes
- Network boundary: service bound to `127.0.0.1:8080`
- Runtime: Asana service and OpenClaw gateway active; public Rocky endpoint
  returned HTTP 200

## Source Of Truth

- Deployment scripts install and verify the service, PAT environment, systemd
  unit, OpenClaw route, and governed Skill.
- Canonical Skill path: `skills/z-asana-agent-control/`
- Service path: `services/asana-http-mcp/`

## Rollback

- Skill backup:
  `/home/openclaw/.openclaw/backups/z-asana-agent-control-20260828-005151`
- Asana route backup:
  `/home/openclaw/.openclaw/backups/asana-http-mcp-20260828-005400`

## Dependency Note

The inherited Asana SDK build tree reports two moderate and two high npm audit
findings. The service builds and runs successfully. Dependency modernization is
a separate hardening task; no automatic audit rewrite was applied during this
deployment.
