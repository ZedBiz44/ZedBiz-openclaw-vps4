# Rocky Notion Write Access Model

Date: 2026-08-25
Author: Cody
Status: Retired

## Historical Record

This page documented the separate `Rocky-Notion-Write-API` integration and
1Password-backed helper. That route was retired after Rocky's OAuth connection
was verified with normal Notion write tools and a harmless write/read-back
test.

Rocky now reads and writes through one unfiltered hosted Notion MCP OAuth
connection. `z-notion-knowledge-publish` governs ZedBiz knowledge publication.
The old write log remains unchanged as audit history, not active infrastructure.

See `docs/rocky-notion-access.md` for the current model.
