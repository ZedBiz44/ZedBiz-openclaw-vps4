import { Tool } from "@modelcontextprotocol/sdk/types.js";

export const getUserTool: Tool = {
  name: "asana_get_user",
  description:
    "Get an Asana user by GID. Defaults to the authenticated user (`me`) for PAT identity verification.",
  inputSchema: {
    type: "object",
    properties: {
      user_gid: {
        type: "string",
        default: "me",
        description: "User GID or `me` for the authenticated PAT identity",
      },
      opt_fields: {
        type: "string",
        default: "gid,name,email,workspaces.gid,workspaces.name",
        description: "Comma-separated optional fields to return",
      },
    },
  },
};
