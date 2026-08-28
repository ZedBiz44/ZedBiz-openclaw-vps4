import { Tool } from "@modelcontextprotocol/sdk/types.js";

export const searchTeamsTool: Tool = {
  name: "asana_search_teams",
  description:
    "Search teams in a workspace by name. Use this before deciding whether a named Asana object is a team, project, or portfolio.",
  inputSchema: {
    type: "object",
    properties: {
      workspace_gid: {
        type: "string",
        description: "Workspace GID containing the teams",
      },
      name_pattern: {
        type: "string",
        description: "Case-insensitive regular expression matched against team names",
      },
      opt_fields: {
        type: "string",
        default: "gid,name,description,html_description",
        description: "Comma-separated optional fields to return",
      },
    },
    required: ["workspace_gid", "name_pattern"],
  },
};

export const getProjectsForTeamTool: Tool = {
  name: "asana_get_projects_for_team",
  description:
    "List projects belonging to a resolved Asana team. This is read-only and requires the team's GID.",
  inputSchema: {
    type: "object",
    properties: {
      team_gid: {
        type: "string",
        description: "Team GID",
      },
      archived: {
        type: "boolean",
        default: false,
        description: "Whether to return archived projects",
      },
      opt_fields: {
        type: "string",
        default: "gid,name,archived,permalink_url,team.gid,team.name",
        description: "Comma-separated optional fields to return",
      },
    },
    required: ["team_gid"],
  },
};
