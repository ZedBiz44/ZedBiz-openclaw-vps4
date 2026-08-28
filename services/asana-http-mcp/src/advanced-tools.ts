import type {
  CallToolRequest,
  CallToolResult,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { AsanaRestClient } from "./asana-rest-client.js";

const text = (description: string) => ({
  type: "string" as const,
  description,
});

const objectSchema = (
  properties: Record<string, any>,
  required: string[] = [],
) => ({
  type: "object" as const,
  properties,
  required,
});

const dataTool = (
  name: string,
  description: string,
  idProperties: Record<string, any>,
  required: string[],
): Tool => ({
  name,
  description,
  inputSchema: objectSchema(
    {
      ...idProperties,
      data: {
        type: "object",
        description: "Asana API fields for this operation",
      },
    },
    required,
  ),
});

export const advancedTools: Tool[] = [
  {
    name: "asana_list_teams",
    description: "List all teams in an Asana workspace",
    inputSchema: objectSchema(
      { workspace_gid: text("Workspace or organization GID") },
      ["workspace_gid"],
    ),
  },
  dataTool(
    "asana_create_team",
    "Create an Asana team",
    { workspace_gid: text("Workspace or organization GID") },
    ["workspace_gid", "data"],
  ),
  dataTool(
    "asana_update_team",
    "Update an Asana team",
    { team_gid: text("Team GID") },
    ["team_gid", "data"],
  ),
  dataTool(
    "asana_add_team_member",
    "Add a user to a team",
    { team_gid: text("Team GID") },
    ["team_gid", "data"],
  ),
  dataTool(
    "asana_remove_team_member",
    "Remove a user from a team",
    { team_gid: text("Team GID") },
    ["team_gid", "data"],
  ),
  {
    name: "asana_get_team_members",
    description: "List team members",
    inputSchema: objectSchema(
      { team_gid: text("Team GID"), opt_fields: text("Optional fields") },
      ["team_gid"],
    ),
  },
  dataTool(
    "asana_create_portfolio",
    "Create a portfolio",
    { workspace_gid: text("Workspace GID") },
    ["workspace_gid", "data"],
  ),
  dataTool(
    "asana_update_portfolio",
    "Update a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  {
    name: "asana_delete_portfolio",
    description: "Delete a portfolio",
    inputSchema: objectSchema(
      { portfolio_gid: text("Portfolio GID") },
      ["portfolio_gid"],
    ),
  },
  dataTool(
    "asana_add_portfolio_item",
    "Add a project to a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_remove_portfolio_item",
    "Remove a project from a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_add_portfolio_members",
    "Add members to a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_remove_portfolio_members",
    "Remove members from a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_add_portfolio_custom_field",
    "Add a custom field to a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_remove_portfolio_custom_field",
    "Remove a custom field from a portfolio",
    { portfolio_gid: text("Portfolio GID") },
    ["portfolio_gid", "data"],
  ),
  dataTool(
    "asana_create_custom_field",
    "Create a workspace custom field",
    { workspace_gid: text("Workspace GID") },
    ["workspace_gid", "data"],
  ),
  dataTool(
    "asana_update_custom_field",
    "Update a custom field",
    { custom_field_gid: text("Custom field GID") },
    ["custom_field_gid", "data"],
  ),
  {
    name: "asana_delete_custom_field",
    description: "Delete a custom field",
    inputSchema: objectSchema(
      { custom_field_gid: text("Custom field GID") },
      ["custom_field_gid"],
    ),
  },
  dataTool(
    "asana_create_enum_option",
    "Create an enum option on a custom field",
    { custom_field_gid: text("Custom field GID") },
    ["custom_field_gid", "data"],
  ),
  dataTool(
    "asana_update_enum_option",
    "Update a custom-field enum option",
    { enum_option_gid: text("Enum option GID") },
    ["enum_option_gid", "data"],
  ),
  dataTool(
    "asana_insert_enum_option",
    "Reorder a custom-field enum option",
    { custom_field_gid: text("Custom field GID") },
    ["custom_field_gid", "data"],
  ),
  dataTool(
    "asana_create_goal",
    "Create a goal",
    { workspace_gid: text("Workspace GID") },
    ["workspace_gid", "data"],
  ),
  dataTool(
    "asana_update_goal",
    "Update a goal",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  {
    name: "asana_delete_goal",
    description: "Delete a goal",
    inputSchema: objectSchema({ goal_gid: text("Goal GID") }, ["goal_gid"]),
  },
  dataTool(
    "asana_update_goal_metric",
    "Create or update a goal metric",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  dataTool(
    "asana_add_goal_followers",
    "Add followers to a goal",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  dataTool(
    "asana_remove_goal_followers",
    "Remove followers from a goal",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  dataTool(
    "asana_add_goal_supporting_work",
    "Add supporting work to a goal",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  dataTool(
    "asana_remove_goal_supporting_work",
    "Remove supporting work from a goal",
    { goal_gid: text("Goal GID") },
    ["goal_gid", "data"],
  ),
  dataTool(
    "asana_add_project_members",
    "Add members to a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  dataTool(
    "asana_remove_project_members",
    "Remove members from a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  dataTool(
    "asana_add_project_followers",
    "Add followers to a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  dataTool(
    "asana_remove_project_followers",
    "Remove followers from a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  dataTool(
    "asana_add_project_custom_field",
    "Add a custom field to a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  dataTool(
    "asana_remove_project_custom_field",
    "Remove a custom field from a project",
    { project_gid: text("Project GID") },
    ["project_gid", "data"],
  ),
  {
    name: "asana_delete_project",
    description: "Delete a project",
    inputSchema: objectSchema(
      { project_gid: text("Project GID") },
      ["project_gid"],
    ),
  },
  dataTool(
    "asana_create_project_from_template",
    "Create a project from an Asana project template",
    { project_template_gid: text("Project template GID") },
    ["project_template_gid", "data"],
  ),
  dataTool(
    "asana_create_task_from_template",
    "Create a task from an Asana task template",
    { task_template_gid: text("Task template GID") },
    ["task_template_gid", "data"],
  ),
  dataTool(
    "asana_add_task_followers",
    "Add followers to a task",
    { task_gid: text("Task GID") },
    ["task_gid", "data"],
  ),
  dataTool(
    "asana_remove_task_followers",
    "Remove followers from a task",
    { task_gid: text("Task GID") },
    ["task_gid", "data"],
  ),
  dataTool(
    "asana_create_webhook",
    "Create an Asana webhook",
    {},
    ["data"],
  ),
  {
    name: "asana_delete_webhook",
    description: "Delete an Asana webhook",
    inputSchema: objectSchema(
      { webhook_gid: text("Webhook GID") },
      ["webhook_gid"],
    ),
  },
  dataTool(
    "asana_create_time_entry",
    "Create a time-tracking entry on a task",
    { task_gid: text("Task GID") },
    ["task_gid", "data"],
  ),
  dataTool(
    "asana_update_time_entry",
    "Update a time-tracking entry",
    { time_entry_gid: text("Time-tracking entry GID") },
    ["time_entry_gid", "data"],
  ),
  {
    name: "asana_delete_time_entry",
    description: "Delete a time-tracking entry",
    inputSchema: objectSchema(
      { time_entry_gid: text("Time-tracking entry GID") },
      ["time_entry_gid"],
    ),
  },
  dataTool(
    "asana_create_allocation",
    "Create a workload allocation",
    {},
    ["data"],
  ),
  dataTool(
    "asana_update_allocation",
    "Update a workload allocation",
    { allocation_gid: text("Allocation GID") },
    ["allocation_gid", "data"],
  ),
  {
    name: "asana_delete_allocation",
    description: "Delete a workload allocation",
    inputSchema: objectSchema(
      { allocation_gid: text("Allocation GID") },
      ["allocation_gid"],
    ),
  },
  dataTool(
    "asana_trigger_rule",
    "Trigger an incoming-web-request Asana rule",
    { rule_trigger_gid: text("Rule trigger GID") },
    ["rule_trigger_gid", "data"],
  ),
  {
    name: "asana_api_request",
    description:
      "Advanced full Asana public API route for supported endpoints not represented by a named tool. Uses only the fixed Asana API host and the agent's own PAT.",
    inputSchema: objectSchema(
      {
        method: {
          type: "string",
          enum: ["GET", "POST", "PUT", "DELETE"],
          description: "HTTP method",
        },
        path: text("Asana API path beginning with one slash, without /api/1.0"),
        query: {
          type: "object",
          description: "Optional query parameters",
          additionalProperties: true,
        },
        data: {
          type: "object",
          description: "Optional Asana request data",
          additionalProperties: true,
        },
      },
      ["method", "path"],
    ),
  },
];

const result = (value: unknown): CallToolResult => ({
  content: [{ type: "text", text: JSON.stringify(value) }],
});

export async function handleAdvancedTool(
  request: CallToolRequest,
  rest: AsanaRestClient,
): Promise<CallToolResult | undefined> {
  const name = request.params.name;
  if (!advancedTools.some((tool) => tool.name === name)) return undefined;
  const args = (request.params.arguments ?? {}) as Record<string, any>;
  const call = (
    method: string,
    path: string,
    data?: unknown,
    query?: Record<string, any>,
  ) => rest.request(method, path, { data, query });

  switch (name) {
    case "asana_list_teams":
      return result(
        await call("GET", `/workspaces/${args.workspace_gid}/teams`, undefined, {
          limit: 100,
        }),
      );
    case "asana_create_team":
      return result(
        await call("POST", "/teams", {
          ...args.data,
          organization: args.workspace_gid,
        }),
      );
    case "asana_update_team":
      return result(await call("PUT", `/teams/${args.team_gid}`, args.data));
    case "asana_add_team_member":
      return result(
        await call("POST", `/teams/${args.team_gid}/addUser`, args.data),
      );
    case "asana_remove_team_member":
      return result(
        await call("POST", `/teams/${args.team_gid}/removeUser`, args.data),
      );
    case "asana_get_team_members":
      return result(
        await call("GET", `/teams/${args.team_gid}/users`, undefined, {
          opt_fields: args.opt_fields ?? "gid,name,email",
          limit: 100,
        }),
      );
    case "asana_create_portfolio":
      return result(
        await call("POST", "/portfolios", {
          ...args.data,
          workspace: args.workspace_gid,
        }),
      );
    case "asana_update_portfolio":
      return result(
        await call("PUT", `/portfolios/${args.portfolio_gid}`, args.data),
      );
    case "asana_delete_portfolio":
      return result(await call("DELETE", `/portfolios/${args.portfolio_gid}`));
    case "asana_add_portfolio_item":
      return result(
        await call("POST", `/portfolios/${args.portfolio_gid}/addItem`, args.data),
      );
    case "asana_remove_portfolio_item":
      return result(
        await call(
          "POST",
          `/portfolios/${args.portfolio_gid}/removeItem`,
          args.data,
        ),
      );
    case "asana_add_portfolio_members":
      return result(
        await call(
          "POST",
          `/portfolios/${args.portfolio_gid}/addMembers`,
          args.data,
        ),
      );
    case "asana_remove_portfolio_members":
      return result(
        await call(
          "POST",
          `/portfolios/${args.portfolio_gid}/removeMembers`,
          args.data,
        ),
      );
    case "asana_add_portfolio_custom_field":
      return result(
        await call(
          "POST",
          `/portfolios/${args.portfolio_gid}/addCustomFieldSetting`,
          args.data,
        ),
      );
    case "asana_remove_portfolio_custom_field":
      return result(
        await call(
          "POST",
          `/portfolios/${args.portfolio_gid}/removeCustomFieldSetting`,
          args.data,
        ),
      );
    case "asana_create_custom_field":
      return result(
        await call("POST", "/custom_fields", {
          ...args.data,
          workspace: args.workspace_gid,
        }),
      );
    case "asana_update_custom_field":
      return result(
        await call("PUT", `/custom_fields/${args.custom_field_gid}`, args.data),
      );
    case "asana_delete_custom_field":
      return result(
        await call("DELETE", `/custom_fields/${args.custom_field_gid}`),
      );
    case "asana_create_enum_option":
      return result(
        await call(
          "POST",
          `/custom_fields/${args.custom_field_gid}/enum_options`,
          args.data,
        ),
      );
    case "asana_update_enum_option":
      return result(
        await call(
          "PUT",
          `/enum_options/${args.enum_option_gid}`,
          args.data,
        ),
      );
    case "asana_insert_enum_option":
      return result(
        await call(
          "POST",
          `/custom_fields/${args.custom_field_gid}/enum_options/insert`,
          args.data,
        ),
      );
    case "asana_create_goal":
      return result(
        await call("POST", "/goals", {
          ...args.data,
          workspace: args.workspace_gid,
        }),
      );
    case "asana_update_goal":
      return result(await call("PUT", `/goals/${args.goal_gid}`, args.data));
    case "asana_delete_goal":
      return result(await call("DELETE", `/goals/${args.goal_gid}`));
    case "asana_update_goal_metric":
      return result(
        await call("POST", `/goals/${args.goal_gid}/setMetric`, args.data),
      );
    case "asana_add_goal_followers":
      return result(
        await call("POST", `/goals/${args.goal_gid}/addFollowers`, args.data),
      );
    case "asana_remove_goal_followers":
      return result(
        await call("POST", `/goals/${args.goal_gid}/removeFollowers`, args.data),
      );
    case "asana_add_goal_supporting_work":
      return result(
        await call(
          "POST",
          `/goals/${args.goal_gid}/addSupportingRelationship`,
          args.data,
        ),
      );
    case "asana_remove_goal_supporting_work":
      return result(
        await call(
          "POST",
          `/goals/${args.goal_gid}/removeSupportingRelationship`,
          args.data,
        ),
      );
    case "asana_add_project_members":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/addMembers`,
          args.data,
        ),
      );
    case "asana_remove_project_members":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/removeMembers`,
          args.data,
        ),
      );
    case "asana_add_project_followers":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/addFollowers`,
          args.data,
        ),
      );
    case "asana_remove_project_followers":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/removeFollowers`,
          args.data,
        ),
      );
    case "asana_add_project_custom_field":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/addCustomFieldSetting`,
          args.data,
        ),
      );
    case "asana_remove_project_custom_field":
      return result(
        await call(
          "POST",
          `/projects/${args.project_gid}/removeCustomFieldSetting`,
          args.data,
        ),
      );
    case "asana_delete_project":
      return result(await call("DELETE", `/projects/${args.project_gid}`));
    case "asana_create_project_from_template":
      return result(
        await call(
          "POST",
          `/project_templates/${args.project_template_gid}/instantiateProject`,
          args.data,
        ),
      );
    case "asana_create_task_from_template":
      return result(
        await call(
          "POST",
          `/task_templates/${args.task_template_gid}/instantiateTask`,
          args.data,
        ),
      );
    case "asana_add_task_followers":
      return result(
        await call("POST", `/tasks/${args.task_gid}/addFollowers`, args.data),
      );
    case "asana_remove_task_followers":
      return result(
        await call("POST", `/tasks/${args.task_gid}/removeFollowers`, args.data),
      );
    case "asana_create_webhook":
      return result(await call("POST", "/webhooks", args.data));
    case "asana_delete_webhook":
      return result(await call("DELETE", `/webhooks/${args.webhook_gid}`));
    case "asana_create_time_entry":
      return result(
        await call(
          "POST",
          `/tasks/${args.task_gid}/time_tracking_entries`,
          args.data,
        ),
      );
    case "asana_update_time_entry":
      return result(
        await call(
          "PUT",
          `/time_tracking_entries/${args.time_entry_gid}`,
          args.data,
        ),
      );
    case "asana_delete_time_entry":
      return result(
        await call(
          "DELETE",
          `/time_tracking_entries/${args.time_entry_gid}`,
        ),
      );
    case "asana_create_allocation":
      return result(await call("POST", "/allocations", args.data));
    case "asana_update_allocation":
      return result(
        await call("PUT", `/allocations/${args.allocation_gid}`, args.data),
      );
    case "asana_delete_allocation":
      return result(await call("DELETE", `/allocations/${args.allocation_gid}`));
    case "asana_trigger_rule":
      return result(
        await call(
          "POST",
          `/rule_triggers/${args.rule_trigger_gid}/run`,
          args.data,
        ),
      );
    case "asana_api_request":
      return result(
        await rest.request(args.method, args.path, {
          query: args.query,
          data: args.data,
        }),
      );
    default:
      return undefined;
  }
}
