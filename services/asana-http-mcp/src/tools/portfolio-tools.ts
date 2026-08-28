import { Tool } from "@modelcontextprotocol/sdk/types.js";

export const listAccessiblePortfoliosTool: Tool = {
  name: "asana_list_accessible_portfolios",
  description:
    "List portfolios the authenticated user owns or can access through portfolio membership in a workspace. This does not bypass Asana privacy.",
  inputSchema: {
    type: "object",
    properties: {
      workspace_gid: {
        type: "string",
        description: "Workspace GID",
      },
      user_gid: {
        type: "string",
        default: "me",
        description: "User GID or `me` for the authenticated PAT identity",
      },
      opt_fields: {
        type: "string",
        default: "gid,name,owner.gid,owner.name,permalink_url,public",
        description: "Comma-separated optional portfolio fields to return",
      },
    },
    required: ["workspace_gid"],
  },
};

export const getPortfolioTool: Tool = {
  name: "asana_get_portfolio",
  description:
    "Get read-only details for a portfolio visible to the authenticated Asana identity.",
  inputSchema: {
    type: "object",
    properties: {
      portfolio_gid: {
        type: "string",
        description: "Portfolio GID",
      },
      opt_fields: {
        type: "string",
        default: "gid,name,owner.gid,owner.name,permalink_url,public,created_at",
        description: "Comma-separated optional fields to return",
      },
    },
    required: ["portfolio_gid"],
  },
};

export const getPortfolioItemsTool: Tool = {
  name: "asana_get_portfolio_items",
  description:
    "List projects and other items inside a portfolio visible to the authenticated Asana identity.",
  inputSchema: {
    type: "object",
    properties: {
      portfolio_gid: {
        type: "string",
        description: "Portfolio GID",
      },
      opt_fields: {
        type: "string",
        default:
          "gid,name,resource_type,archived,completed,current_status.title,current_status.color,owner.gid,owner.name,team.gid,team.name,permalink_url",
        description: "Comma-separated optional fields to return",
      },
    },
    required: ["portfolio_gid"],
  },
};
