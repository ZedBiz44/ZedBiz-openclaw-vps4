# Rocky Standard Asana HTTP MCP

Date: 2026-08-28 | Agent: Cody | Status: Approved source

This is the ZedBiz 76-tool Standard Asana Streamable HTTP MCP adapted for
Rocky's native VPS4 runtime. The governed source was imported from commit
`3445c50` in `ZedBiz-openclaw-ai-agents-vps1-vps2`.

- Asana authentication remains Rocky's `ASANA_ACCESS_TOKEN` from 1Password.
- The MCP listener defaults to `127.0.0.1` and must not be exposed publicly.
- The local MCP bearer token reuses Rocky's PAT, matching the approved pilot.
- The service exposes `/healthz` and `/mcp` on port `8080`.
- `scripts/12-configure-rocky-asana-mcp.sh` installs and verifies the service.

Upstream portions remain under the included MIT license and are based on
`@roychri/mcp-server-asana` 1.8.0.
