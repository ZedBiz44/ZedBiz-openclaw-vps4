import https from "node:https";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { startHttpMcpService } from "./http-runtime.js";

const ASANA_TOKEN = process.env.ASANA_ACCESS_TOKEN;
const WORKSPACE_GID = process.env.ASANA_WORKSPACE_GID ?? "11298561585567";

if (!ASANA_TOKEN) throw new Error("ASANA_ACCESS_TOKEN is required");

type JsonRecord = Record<string, any>;

function asanaRequest(method: string, path: string, body?: JsonRecord): Promise<JsonRecord> {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify({ data: body }) : undefined;
    const request = https.request(
      {
        hostname: "app.asana.com",
        path: `/api/1.0${path}`,
        method,
        headers: {
          Authorization: `Bearer ${ASANA_TOKEN}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}),
        },
        timeout: 30_000,
      },
      (response) => {
        let raw = "";
        response.setEncoding("utf8");
        response.on("data", (chunk) => {
          raw += chunk;
        });
        response.on("end", () => {
          try {
            const parsed = JSON.parse(raw || "{}");
            if ((response.statusCode ?? 500) >= 400) {
              reject(new Error(parsed.errors?.[0]?.message ?? `Asana HTTP ${response.statusCode}`));
              return;
            }
            resolve(parsed);
          } catch (error) {
            reject(new Error(`Invalid Asana response: ${String(error)}`));
          }
        });
      },
    );
    request.on("timeout", () => request.destroy(new Error("Asana request timed out")));
    request.on("error", reject);
    if (data) request.write(data);
    request.end();
  });
}

const TOOLS = [
  {
    name: "asana_list_teams",
    description: "List all teams in the Asana workspace",
    inputSchema: { type: "object", properties: {}, required: [] },
  },
  {
    name: "asana_update_team",
    description: "Rename or update a team in Asana. Provide the team GID and the new name.",
    inputSchema: {
      type: "object",
      properties: {
        team_gid: { type: "string", description: "GID of the team to update" },
        name: { type: "string", description: "New name for the team" },
        description: { type: "string", description: "New description (optional)" },
      },
      required: ["team_gid", "name"],
    },
  },
  {
    name: "asana_create_team",
    description: "Create a new team in the Asana workspace",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string", description: "Name of the new team" },
        description: { type: "string", description: "Description (optional)" },
        visibility: {
          type: "string",
          enum: ["secret", "request_to_join", "public"],
          description: "Visibility (default: secret)",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "asana_add_team_member",
    description: "Add a user to an Asana team as admin or member",
    inputSchema: {
      type: "object",
      properties: {
        team_gid: { type: "string", description: "GID of the team" },
        user_gid: { type: "string", description: "GID of the user to add" },
        role: {
          type: "string",
          enum: ["admin", "member"],
          description: "Role (default: member)",
        },
      },
      required: ["team_gid", "user_gid"],
    },
  },
  {
    name: "asana_remove_team_member",
    description: "Remove a user from an Asana team",
    inputSchema: {
      type: "object",
      properties: {
        team_gid: { type: "string", description: "GID of the team" },
        user_gid: { type: "string", description: "GID of the user to remove" },
      },
      required: ["team_gid", "user_gid"],
    },
  },
  {
    name: "asana_get_team_members",
    description: "List all members of an Asana team",
    inputSchema: {
      type: "object",
      properties: {
        team_gid: { type: "string", description: "GID of the team" },
      },
      required: ["team_gid"],
    },
  },
];

async function handleTool(name: string, args: JsonRecord): Promise<JsonRecord> {
  switch (name) {
    case "asana_list_teams": {
      const teams: JsonRecord[] = [];
      let offset: string | undefined;
      do {
        const path = `/workspaces/${WORKSPACE_GID}/teams?limit=50${
          offset ? `&offset=${encodeURIComponent(offset)}` : ""
        }`;
        const response = await asanaRequest("GET", path);
        teams.push(...(response.data ?? []));
        offset = response.next_page?.offset;
      } while (offset);
      return { teams: teams.map((team) => ({ gid: team.gid, name: team.name })) };
    }
    case "asana_update_team": {
      const body: JsonRecord = { name: args.name };
      if (args.description !== undefined) body.description = args.description;
      const response = await asanaRequest("PUT", `/teams/${args.team_gid}`, body);
      return { updated: { gid: response.data.gid, name: response.data.name } };
    }
    case "asana_create_team": {
      const body: JsonRecord = {
        name: args.name,
        organization: WORKSPACE_GID,
        visibility: args.visibility ?? "secret",
      };
      if (args.description) body.description = args.description;
      const response = await asanaRequest("POST", "/teams", body);
      return { created: { gid: response.data.gid, name: response.data.name } };
    }
    case "asana_add_team_member": {
      const body: JsonRecord = { user: args.user_gid };
      if (args.role === "admin") body.role = "admin";
      const response = await asanaRequest("POST", `/teams/${args.team_gid}/addUser`, body);
      return {
        membership: {
          gid: response.data.gid,
          user: response.data.user,
          is_admin: response.data.is_admin,
          team: response.data.team,
        },
      };
    }
    case "asana_remove_team_member":
      await asanaRequest("POST", `/teams/${args.team_gid}/removeUser`, {
        user: args.user_gid,
      });
      return { removed: true };
    case "asana_get_team_members": {
      const response = await asanaRequest(
        "GET",
        `/teams/${args.team_gid}/users?opt_fields=gid,name,email`,
      );
      return { members: response.data ?? [] };
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

function createTeamServer(): Server {
  const server = new Server(
    { name: "ZedBiz Asana Team MCP", version: "1.0.0" },
    { capabilities: { tools: {} } },
  );
  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
      const result = await handleTool(name, args ?? {});
      return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${(error as Error).message}` }],
        isError: true,
      };
    }
  });
  return server;
}

startHttpMcpService({
  serviceName: "ZedBiz Asana Team MCP",
  createServer: createTeamServer,
}).catch((error) => {
  console.error("Fatal Asana Team HTTP MCP error:", error);
  process.exit(1);
});
