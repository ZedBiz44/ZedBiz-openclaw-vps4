---
name: z-asana-agent-control
description: Use for ZedBiz agent Asana work to verify PAT identity, enforce workspace boundaries, and safely manage assigned tasks.
---

# Z Asana Agent Control

## Purpose

Use this skill for normal assigned Asana task work.

This skill uses the 76-tool Asana Standard HTTP MCP. It covers the normal work an
agent needs inside teams, projects, tasks, and subtasks, including sections,
project updates/statuses, project briefs, tags, attachments, dates,
dependencies, blockers, task-level custom fields, read-only goals, and
read-only portfolio navigation.

It is not for team administration, portfolio changes, workspace custom-field
administration, goals administration, webhooks, organization-level operations,
or unrestricted API operations. Those belong in the Advanced Asana Skill.

## Required Identity

Required values:

- `AGENT_NAME`
- `ASANA_AGENT_EMAIL`
- `ASANA_AGENT_USER_NAME`
- `ASANA_AGENT_USER_GID`
- `ASANA_MCP_SERVER`
- `ASANA_WORKSPACE_GID`

If missing, stop before Asana task work.

## Stop Immediately If

- Asana identity is Jack or another user.
- PAT MCP is missing, unhealthy, or token auth fails.
- Workspace GID does not match.
- Required identity values are missing.
- Tool path is unknown or only Jack-authenticated Codex Asana is available.

## Tool Routing

Use only the agent's PAT-based Asana MCP for agent task execution.

Do not use Jack-authenticated Codex/ChatGPT Asana tools for agent-owned task work.

If `mcp__codex_apps__asana` returns Jack, treat that connector as the wrong route, not as the final answer. Continue looking for the OpenClaw PAT MCP route before stopping.

Preferred route names and checks:

- OpenClaw MCP server named `asana`
- Config entry using the approved persistent Streamable HTTP service
- `openclaw mcp list`
- MCP tools exposed from the `asana` server in the active agent runtime

Treat a successful `asana_get_user` or another real read-only PAT tool call as the authoritative connectivity check. For Streamable HTTP routes, use the service `/healthz` endpoint when shell access is available.

Do not block solely because `openclaw mcp probe asana` reports an HTTP/SSE 400. The current probe uses a legacy SSE-style GET that is incompatible with the approved Streamable HTTP endpoint even when real MCP tool calls work.

If the PAT MCP route is callable, use it and continue. If the PAT MCP route exists in config but is not callable in the active session, stop with `Blocked on tool exposure: Asana PAT MCP is configured but not exposed to this session.`

## Identity Preflight

Before Asana work, call `asana_get_user` with `user_gid: "me"` through the PAT MCP.

Continue only if:

- `me.email` equals `ASANA_AGENT_EMAIL`
- workspace includes `ASANA_WORKSPACE_GID`

If not, stop and report the wrong Asana authority path.

Failure message: `Asana work stopped. Expected AGENT_NAME as ASANA_AGENT_EMAIL in ASANA_WORKSPACE_GID, but Asana returned ACTUAL_EMAIL through TOOL_PATH. Fix PAT MCP before task execution continues.`

## Clarified Non-Features

Do not include unrestricted endpoint support in this regular skill. The approved
OpenClaw route is the ZedBiz 76-tool Standard HTTP service, based on
`@roychri/mcp-server-asana`, using the agent's own `ASANA_ACCESS_TOKEN`.

Do not use `notion-rest` as an Asana authentication fallback. If PAT MCP auth fails, stop and fix the Asana MCP setup. Direct Asana REST is diagnosis-only and requires Jack approval plus the same approved agent PAT.

## Tool Path Audit

Before work, identify:

- Asana tool server
- authenticated email
- authenticated user GID
- workspace GID
- whether this is PAT MCP or Codex connector

Minimum required config: PAT MCP server, current-user lookup, assigned-task
search, task read/comment/update/complete, workspace GID, team search,
team-project listing, sections, project statuses, project briefs, tags,
attachments, dependencies/blockers, and read-only portfolio navigation.

## GID Rule

Resolve names and emails to GIDs before task queries or updates.

Use the agent user GID from `me` for the agent's own assigned tasks. Use typeahead/search for users, tasks, projects, sections, tags, and custom fields. If multiple matches exist, do not guess.

## Object Type Resolution

Never infer that an Asana name is a portfolio merely because project search returned no match.

When the object type is unclear:

- Search projects with `asana_search_projects`.
- Search teams with `asana_search_teams`.
- Inspect portfolios visible to the authenticated agent with `asana_list_accessible_portfolios`.
- Compare exact names and report the confirmed object type and GID.

For a team question such as "what projects are inside TEAM_NAME":

- Resolve the team with `asana_search_teams`.
- Pass the resolved team GID to `asana_get_projects_for_team`.
- Report the returned projects without changing Asana.

For a portfolio question:

- Use `asana_list_accessible_portfolios`, `asana_get_portfolio`, and `asana_get_portfolio_items`.
- Respect Asana permissions. An empty result means no visible portfolio membership or ownership; it does not prove that no portfolios exist.
- Portfolio membership, sharing, role, or structure changes require the Advanced Asana Skill and confirmation.

## Safe Action Levels

Safe: read assigned tasks, read comments/subtasks/attachments/dependencies/custom fields, add progress comments.

Normal: update assigned task, complete assigned task after done criteria, upload relevant attachments, create small follow-up subtasks, add needed followers.

Risky: move between existing sections, update custom fields, add/remove dependencies, reassign tasks, change one task due date. Do only when the task explicitly says to do it, the work clearly requires it, or Jack approved.

Restricted: team administration, portfolio mutations, workspace custom-field
administration, goals administration, webhooks, broad deletes, or unrestricted
API requests. Use Advanced Asana Skill.

Project briefs and project status updates are available in Standard. Draft
first and publish only when the assignment or Jack authorizes the publication.
Project setup, workflow changes, bulk date shifts, and deletes still require
explicit authorization even when the Standard tool exists.

## Task Discovery

Find incomplete tasks assigned to `ASANA_AGENT_USER_GID`.

Do not browse all Asana tasks/projects unless the assigned task requires that broader search.

Prioritize urgent/high priority, tasks blocking other agents, near due dates, then older actionable work.

Never use `my tasks` unless identity preflight confirms the authenticated user is this agent.

## Blocker Check

Before starting, check dependencies and blockers. Skip blocked tasks unless Jack asked for blocker diagnosis. If the agent's task blocks others, treat it as higher priority.

## Claiming Work

When starting, add a short `Starting work` comment and move/set task to `In Progress` if the project uses that status.

Do not duplicate work already active by another agent/person unless directly assigned or Jack says to continue.

Keep Asana comments concise, evidence-based, and tied to the task outcome.

## Mode Handling

Get-er-Done Mode: execute the simplest useful version, test in the real workflow, update the task with proof, and complete only when done criteria are met.

Diagnose Mode: Diagnose, Solution, Confirmation, Act. Stop and ask before changes.

## Completion

Before completing, confirm done criteria, add proof/result links, add a final comment, and create/mention follow-up work if needed.

## Custom Fields

Enumerate custom fields before using them. Use field GIDs and enum option GIDs. Never guess. Regular agents may update task-level fields only when needed for assigned work.

## Mentions And Rich Text

Use valid `html_notes` / `html_text` when needed. For reliable mentions, add follower, wait about 2.5 seconds, then comment with the Asana mention tag.

## Attachments

Upload relevant task, project, or project-brief attachments when the assignment
requires them. Confirm the correct parent GID before upload.

## Scheduled Checks

For recurring scheduled agents, use Events/sync-token discovery when available. Normal interactive checks can query assigned tasks directly.

Store sync tokens only in approved local runtime state, not in prompts, Notion pages, task comments, or chat.

## Allowed And Forbidden Examples

Allowed: check assigned incomplete tasks, comment with progress, upload proof, complete a task after done criteria are met.

Forbidden without Jack/Advanced Skill: indiscriminately browse the whole
workspace, redesign a project, bulk shift dates, delete items, administer
teams, create or change portfolios, or change workspace custom-field systems.

## Troubleshooting

Check tool path, identity preflight, workspace GID, MCP registration, token injection, GID resolution, permissions, and rate limits. If MCP auth fails, do not use `notion-rest` as a workaround.

## Security

Never store, repeat, paste, or document real Asana PAT values in prompts, chat, Notion, GitHub, task comments, or skill files. PATs belong only in the approved secret store and runtime environment.
