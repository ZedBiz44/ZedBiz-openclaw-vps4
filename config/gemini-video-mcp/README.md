# Rocky Gemini video MCP dependency record

These manifests describe the existing custom `z-gemini-video-mcp` version 0.2.0 installed at `/home/openclaw/.local/share/openclaw-tools/z-gemini-video-mcp-v020` on VPS4. They accompany its existing server implementation; this directory is not a standalone replacement server.

The 2026-10-03 maintenance updated Google GenAI, MCP SDK and Zod dependencies and retained the application code. The full npm audit returned zero findings. `maintenance-validation.mjs` verifies tool discovery and rejection of invalid inputs with a placeholder key, without submitting a paid analysis request. Run it beside the installed server and its dependencies.

The prior runtime was backed up before atomic replacement. See the dated maintenance record and issue #57 for live verification and rollback evidence.
