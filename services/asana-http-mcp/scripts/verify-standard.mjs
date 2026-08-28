import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const [expectedUserGid, expectedEmail, expectedWorkspaceGid] = process.argv.slice(2);
if (!expectedUserGid || !expectedEmail || !expectedWorkspaceGid) {
  throw new Error("Usage: verify-standard.mjs <user-gid> <email> <workspace-gid>");
}

const token = process.env.MCP_AUTH_TOKEN;
if (!token) throw new Error("MCP_AUTH_TOKEN is missing");

const client = new Client({ name: "rocky-asana-verify", version: "2.0.0" });
const transport = new StreamableHTTPClientTransport(
  new URL("http://127.0.0.1:8080/mcp"),
  { requestInit: { headers: { Authorization: `Bearer ${token}` } } },
);

const call = async (name, args) => {
  const response = await client.callTool({ name, arguments: args });
  if (response.isError) throw new Error(`${name} returned an MCP error`);
  const value = JSON.parse(response.content[0].text);
  if (value?.error) throw new Error(`${name}: ${value.error}`);
  return value;
};

try {
  await client.connect(transport);
  const listed = await client.listTools();
  const names = listed.tools.map((tool) => tool.name);
  if (names.length !== 76) throw new Error(`Expected 76 tools, received ${names.length}`);
  for (const required of [
    "asana_get_user",
    "asana_search_tasks",
    "asana_update_task",
    "asana_create_project_brief",
    "asana_upload_attachment",
    "asana_get_task_dependencies",
    "asana_get_portfolio_items",
  ]) {
    if (!names.includes(required)) throw new Error(`Missing ${required}`);
  }

  const me = await call("asana_get_user", { user_gid: "me" });
  const workspaceMatch = me.workspaces?.some(
    (workspace) => workspace.gid === expectedWorkspaceGid,
  );
  if (me.gid !== expectedUserGid || me.email !== expectedEmail || !workspaceMatch) {
    throw new Error("Rocky Asana identity or workspace did not match");
  }

  console.log(JSON.stringify({
    ok: true,
    toolCount: names.length,
    identity: { gid: me.gid, email: me.email },
    workspaceGid: expectedWorkspaceGid,
  }));
} finally {
  await client.close();
}
