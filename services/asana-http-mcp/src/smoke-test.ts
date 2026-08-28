import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = process.env.SMOKE_URL;
const token = process.env.MCP_AUTH_TOKEN;
const expectedTools = Number.parseInt(process.env.EXPECTED_TOOLS ?? "", 10);

if (!url || !token) {
  throw new Error("SMOKE_URL and MCP_AUTH_TOKEN are required");
}

const client = new Client({ name: "zedbiz-mcp-smoke-test", version: "1.0.0" });
const transport = new StreamableHTTPClientTransport(new URL(url), {
  requestInit: {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  },
});

try {
  await client.connect(transport);
  const result = await client.listTools();
  if (Number.isFinite(expectedTools) && result.tools.length !== expectedTools) {
    throw new Error(`Expected ${expectedTools} tools, received ${result.tools.length}`);
  }
  console.log(
    JSON.stringify({
      ok: true,
      url,
      toolCount: result.tools.length,
      tools: result.tools.map((tool) => tool.name),
    }),
  );
} finally {
  await client.close();
}
