#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { AsanaClientWrapper } from "./asana-client-wrapper.js";
import { AsanaRestClient } from "./asana-rest-client.js";
import { advancedTools, handleAdvancedTool } from "./advanced-tools.js";
import { startHttpMcpService } from "./http-runtime.js";
import { list_of_tools, tool_handler } from "./tool-handler.js";
import { VERSION } from "./version.js";

function createAdvancedServer(): Server {
  const token = process.env.ASANA_ACCESS_TOKEN;
  if (!token) throw new Error("ASANA_ACCESS_TOKEN is required");

  const asana = new AsanaClientWrapper(token);
  const rest = new AsanaRestClient(token);
  const standardHandler = tool_handler(asana, rest);
  const tools = [...list_of_tools, ...advancedTools];
  const duplicateNames = tools
    .map((tool) => tool.name)
    .filter((name, index, names) => names.indexOf(name) !== index);
  if (duplicateNames.length) {
    throw new Error(`Duplicate advanced tool names: ${duplicateNames.join(", ")}`);
  }

  const server = new Server(
    { name: "ZedBiz Asana Advanced MCP", version: VERSION },
    { capabilities: { tools: {} } },
  );
  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const advancedResult = await handleAdvancedTool(request, rest);
    return advancedResult ?? standardHandler(request);
  });
  return server;
}

startHttpMcpService({
  serviceName: "ZedBiz Asana Advanced MCP",
  createServer: createAdvancedServer,
}).catch((error) => {
  console.error("Fatal Asana Advanced HTTP MCP error:", error);
  process.exit(1);
});
