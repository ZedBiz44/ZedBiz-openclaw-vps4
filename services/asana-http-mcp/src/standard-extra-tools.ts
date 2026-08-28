import type {
  CallToolRequest,
  CallToolResult,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { AsanaRestClient } from "./asana-rest-client.js";

const stringProperty = (description: string) => ({
  type: "string" as const,
  description,
});

export const standardExtraTools: Tool[] = [
  {
    name: "asana_get_users",
    description: "List users in an Asana workspace or team",
    inputSchema: {
      type: "object",
      properties: {
        workspace_gid: stringProperty("Workspace GID"),
        team_gid: stringProperty("Optional team GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["workspace_gid"],
    },
  },
  {
    name: "asana_get_user_task_list",
    description: "Get a user's My Tasks list for a workspace",
    inputSchema: {
      type: "object",
      properties: {
        user_gid: stringProperty("User GID or me"),
        workspace_gid: stringProperty("Workspace GID"),
      },
      required: ["user_gid", "workspace_gid"],
    },
  },
  {
    name: "asana_get_user_favorites",
    description: "List a user's favorite Asana objects",
    inputSchema: {
      type: "object",
      properties: {
        user_gid: stringProperty("User GID or me"),
        workspace_gid: stringProperty("Workspace GID"),
        resource_type: stringProperty("Optional favorite resource type"),
      },
      required: ["user_gid", "workspace_gid"],
    },
  },
  {
    name: "asana_search_objects",
    description:
      "Universal Asana typeahead search for projects, tasks, portfolios, goals, users, teams, tags, custom fields, agents, or actors",
    inputSchema: {
      type: "object",
      properties: {
        workspace_gid: stringProperty("Workspace GID"),
        resource_type: stringProperty("Asana resource type"),
        query: stringProperty("Search text"),
        count: { type: "integer", minimum: 1, maximum: 100, default: 20 },
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["workspace_gid", "resource_type", "query"],
    },
  },
  {
    name: "asana_get_attachments",
    description: "List attachments on a task, project, or project brief",
    inputSchema: {
      type: "object",
      properties: {
        parent_gid: stringProperty("Task, project, or project brief GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["parent_gid"],
    },
  },
  {
    name: "asana_get_attachment",
    description: "Get one Asana attachment",
    inputSchema: {
      type: "object",
      properties: {
        attachment_gid: stringProperty("Attachment GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["attachment_gid"],
    },
  },
  {
    name: "asana_upload_attachment",
    description:
      "Attach an external URL or base64-encoded file to a task, project, or project brief",
    inputSchema: {
      type: "object",
      properties: {
        parent_gid: stringProperty("Parent task, project, or project brief GID"),
        name: stringProperty("Attachment file or link name"),
        url: stringProperty("External URL to attach"),
        base64_data: stringProperty("Base64-encoded file contents"),
        content_type: stringProperty("MIME type for base64_data"),
      },
      required: ["parent_gid"],
    },
  },
  {
    name: "asana_delete_attachment",
    description: "Delete an Asana attachment",
    inputSchema: {
      type: "object",
      properties: { attachment_gid: stringProperty("Attachment GID") },
      required: ["attachment_gid"],
    },
  },
  {
    name: "asana_get_project_brief",
    description: "Get a project brief",
    inputSchema: {
      type: "object",
      properties: {
        project_brief_gid: stringProperty("Project brief GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["project_brief_gid"],
    },
  },
  {
    name: "asana_create_project_brief",
    description: "Create a project brief",
    inputSchema: {
      type: "object",
      properties: {
        project_gid: stringProperty("Project GID"),
        title: stringProperty("Brief title"),
        text: stringProperty("Plain-text brief body"),
        html_text: stringProperty("Asana-compatible HTML brief body"),
      },
      required: ["project_gid", "title"],
    },
  },
  {
    name: "asana_update_project_brief",
    description: "Update a project brief",
    inputSchema: {
      type: "object",
      properties: {
        project_brief_gid: stringProperty("Project brief GID"),
        title: stringProperty("Brief title"),
        text: stringProperty("Plain-text brief body"),
        html_text: stringProperty("Asana-compatible HTML brief body"),
      },
      required: ["project_brief_gid"],
    },
  },
  {
    name: "asana_delete_project_brief",
    description: "Delete a project brief",
    inputSchema: {
      type: "object",
      properties: {
        project_brief_gid: stringProperty("Project brief GID"),
      },
      required: ["project_brief_gid"],
    },
  },
  {
    name: "asana_get_project_memberships",
    description: "List memberships and access levels for a project",
    inputSchema: {
      type: "object",
      properties: {
        project_gid: stringProperty("Project GID"),
        user_gid: stringProperty("Optional user GID filter"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["project_gid"],
    },
  },
  {
    name: "asana_get_task_dependencies",
    description: "List tasks that block the target task",
    inputSchema: {
      type: "object",
      properties: { task_gid: stringProperty("Task GID") },
      required: ["task_gid"],
    },
  },
  {
    name: "asana_get_task_dependents",
    description: "List tasks blocked by the target task",
    inputSchema: {
      type: "object",
      properties: { task_gid: stringProperty("Task GID") },
      required: ["task_gid"],
    },
  },
  {
    name: "asana_remove_task_dependencies",
    description: "Remove one or more dependency relationships from a task",
    inputSchema: {
      type: "object",
      properties: {
        task_gid: stringProperty("Task GID"),
        dependency_gids: {
          type: "array",
          items: { type: "string" },
          minItems: 1,
        },
      },
      required: ["task_gid", "dependency_gids"],
    },
  },
  {
    name: "asana_remove_task_dependents",
    description: "Remove one or more dependent relationships from a task",
    inputSchema: {
      type: "object",
      properties: {
        task_gid: stringProperty("Task GID"),
        dependent_gids: {
          type: "array",
          items: { type: "string" },
          minItems: 1,
        },
      },
      required: ["task_gid", "dependent_gids"],
    },
  },
  {
    name: "asana_duplicate_task",
    description: "Duplicate a task and selected related data",
    inputSchema: {
      type: "object",
      properties: {
        task_gid: stringProperty("Task GID"),
        name: stringProperty("Optional new task name"),
        include: {
          type: "array",
          items: { type: "string" },
          description: "Asana duplicate include options",
        },
      },
      required: ["task_gid"],
    },
  },
  {
    name: "asana_duplicate_project",
    description: "Duplicate a project and selected related data",
    inputSchema: {
      type: "object",
      properties: {
        project_gid: stringProperty("Project GID"),
        name: stringProperty("New project name"),
        team_gid: stringProperty("Optional destination team GID"),
        include: {
          type: "array",
          items: { type: "string" },
          description: "Asana duplicate include options",
        },
      },
      required: ["project_gid", "name"],
    },
  },
  {
    name: "asana_get_status_overview",
    description:
      "Get project or portfolio details together with status updates and project task counts",
    inputSchema: {
      type: "object",
      properties: {
        parent_gid: stringProperty("Project or portfolio GID"),
        parent_type: {
          type: "string",
          enum: ["project", "portfolio"],
        },
      },
      required: ["parent_gid", "parent_type"],
    },
  },
  {
    name: "asana_get_goals",
    description: "List goals visible in a workspace",
    inputSchema: {
      type: "object",
      properties: {
        workspace_gid: stringProperty("Workspace GID"),
        team_gid: stringProperty("Optional team GID"),
        portfolio_gid: stringProperty("Optional portfolio GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["workspace_gid"],
    },
  },
  {
    name: "asana_get_goal",
    description: "Get one goal",
    inputSchema: {
      type: "object",
      properties: {
        goal_gid: stringProperty("Goal GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["goal_gid"],
    },
  },
  {
    name: "asana_get_custom_fields",
    description: "List custom fields in a workspace",
    inputSchema: {
      type: "object",
      properties: {
        workspace_gid: stringProperty("Workspace GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["workspace_gid"],
    },
  },
  {
    name: "asana_get_custom_field",
    description: "Get one custom field and its enum options",
    inputSchema: {
      type: "object",
      properties: {
        custom_field_gid: stringProperty("Custom field GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["custom_field_gid"],
    },
  },
  {
    name: "asana_get_project_custom_field_settings",
    description: "List custom-field settings attached to a project",
    inputSchema: {
      type: "object",
      properties: {
        project_gid: stringProperty("Project GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["project_gid"],
    },
  },
  {
    name: "asana_get_portfolio_custom_field_settings",
    description: "List custom-field settings attached to a portfolio",
    inputSchema: {
      type: "object",
      properties: {
        portfolio_gid: stringProperty("Portfolio GID"),
        opt_fields: stringProperty("Optional comma-separated fields"),
      },
      required: ["portfolio_gid"],
    },
  },
  {
    name: "asana_preview_task_changes",
    description:
      "Validate and return a dry-run preview for bulk task create or update operations without changing Asana",
    inputSchema: {
      type: "object",
      properties: {
        operation: { type: "string", enum: ["create", "update"] },
        tasks: {
          type: "array",
          items: { type: "object" },
          minItems: 1,
          maxItems: 50,
        },
      },
      required: ["operation", "tasks"],
    },
  },
  {
    name: "asana_create_tasks_bulk",
    description: "Create up to 50 tasks in one controlled operation",
    inputSchema: {
      type: "object",
      properties: {
        tasks: {
          type: "array",
          items: { type: "object" },
          minItems: 1,
          maxItems: 50,
        },
      },
      required: ["tasks"],
    },
  },
  {
    name: "asana_update_tasks_bulk",
    description: "Update up to 50 tasks in one controlled operation",
    inputSchema: {
      type: "object",
      properties: {
        tasks: {
          type: "array",
          items: {
            type: "object",
            properties: {
              task_gid: { type: "string" },
              data: { type: "object" },
            },
            required: ["task_gid", "data"],
          },
          minItems: 1,
          maxItems: 50,
        },
      },
      required: ["tasks"],
    },
  },
];

const textResult = (value: unknown): CallToolResult => ({
  content: [{ type: "text", text: JSON.stringify(value) }],
});

const cleanData = (args: Record<string, any>, omitted: string[]) =>
  Object.fromEntries(
    Object.entries(args).filter(
      ([key, value]) => !omitted.includes(key) && value !== undefined,
    ),
  );

async function runBulk<T>(
  items: T[],
  action: (item: T) => Promise<any>,
): Promise<any[]> {
  if (!items.length || items.length > 50) {
    throw new Error("Bulk operations require between 1 and 50 items");
  }
  const results: any[] = [];
  for (let index = 0; index < items.length; index += 5) {
    const chunk = items.slice(index, index + 5);
    results.push(...(await Promise.all(chunk.map(action))));
  }
  return results;
}

export async function handleStandardExtraTool(
  request: CallToolRequest,
  rest: AsanaRestClient,
): Promise<CallToolResult | undefined> {
  const name = request.params.name;
  if (!standardExtraTools.some((tool) => tool.name === name)) return undefined;
  const args = (request.params.arguments ?? {}) as Record<string, any>;

  switch (name) {
    case "asana_get_users":
      return textResult(
        await rest.request(
          "GET",
          args.team_gid
            ? `/teams/${args.team_gid}/users`
            : `/workspaces/${args.workspace_gid}/users`,
          { query: { opt_fields: args.opt_fields, limit: 100 } },
        ),
      );
    case "asana_get_user_task_list":
      return textResult(
        await rest.request(
          "GET",
          `/users/${args.user_gid}/user_task_list`,
          { query: { workspace: args.workspace_gid } },
        ),
      );
    case "asana_get_user_favorites":
      return textResult(
        await rest.request("GET", `/users/${args.user_gid}/favorites`, {
          query: {
            workspace: args.workspace_gid,
            resource_type: args.resource_type,
          },
        }),
      );
    case "asana_search_objects":
      return textResult(
        await rest.request(
          "GET",
          `/workspaces/${args.workspace_gid}/typeahead`,
          {
            query: {
              resource_type: args.resource_type,
              query: args.query,
              count: args.count ?? 20,
              opt_fields: args.opt_fields,
            },
          },
        ),
      );
    case "asana_get_attachments":
      return textResult(
        await rest.request("GET", "/attachments", {
          query: {
            parent: args.parent_gid,
            opt_fields:
              args.opt_fields ??
              "gid,name,resource_subtype,created_at,download_url,permanent_url,view_url,parent",
          },
        }),
      );
    case "asana_get_attachment":
      return textResult(
        await rest.request("GET", `/attachments/${args.attachment_gid}`, {
          query: { opt_fields: args.opt_fields },
        }),
      );
    case "asana_upload_attachment":
      return textResult(
        await rest.uploadAttachment({
          parent: args.parent_gid,
          name: args.name,
          url: args.url,
          base64_data: args.base64_data,
          content_type: args.content_type,
        }),
      );
    case "asana_delete_attachment":
      return textResult(
        await rest.request("DELETE", `/attachments/${args.attachment_gid}`),
      );
    case "asana_get_project_brief":
      return textResult(
        await rest.request(
          "GET",
          `/project_briefs/${args.project_brief_gid}`,
          { query: { opt_fields: args.opt_fields } },
        ),
      );
    case "asana_create_project_brief":
      return textResult(
        await rest.request(
          "POST",
          `/projects/${args.project_gid}/project_briefs`,
          { data: cleanData(args, ["project_gid"]) },
        ),
      );
    case "asana_update_project_brief":
      return textResult(
        await rest.request(
          "PUT",
          `/project_briefs/${args.project_brief_gid}`,
          { data: cleanData(args, ["project_brief_gid"]) },
        ),
      );
    case "asana_delete_project_brief":
      return textResult(
        await rest.request(
          "DELETE",
          `/project_briefs/${args.project_brief_gid}`,
        ),
      );
    case "asana_get_project_memberships":
      return textResult(
        await rest.request("GET", "/project_memberships", {
          query: {
            project: args.project_gid,
            user: args.user_gid,
            opt_fields:
              args.opt_fields ??
              "gid,access_level,user.gid,user.name,user.email,project.gid,project.name",
          },
        }),
      );
    case "asana_get_task_dependencies":
      return textResult(
        await rest.request("GET", `/tasks/${args.task_gid}/dependencies`),
      );
    case "asana_get_task_dependents":
      return textResult(
        await rest.request("GET", `/tasks/${args.task_gid}/dependents`),
      );
    case "asana_remove_task_dependencies":
      return textResult(
        await rest.request(
          "POST",
          `/tasks/${args.task_gid}/removeDependencies`,
          { data: { dependencies: args.dependency_gids } },
        ),
      );
    case "asana_remove_task_dependents":
      return textResult(
        await rest.request("POST", `/tasks/${args.task_gid}/removeDependents`, {
          data: { dependents: args.dependent_gids },
        }),
      );
    case "asana_duplicate_task":
      return textResult(
        await rest.request("POST", `/tasks/${args.task_gid}/duplicate`, {
          data: cleanData(args, ["task_gid"]),
        }),
      );
    case "asana_duplicate_project":
      return textResult(
        await rest.request("POST", `/projects/${args.project_gid}/duplicate`, {
          data: {
            name: args.name,
            team: args.team_gid,
            include: args.include,
          },
        }),
      );
    case "asana_get_status_overview": {
      const parentPath =
        args.parent_type === "project"
          ? `/projects/${args.parent_gid}`
          : `/portfolios/${args.parent_gid}`;
      const [parent, statuses, taskCounts] = await Promise.all([
        rest.request("GET", parentPath, {
          query: {
            opt_fields:
              "gid,name,owner,team,due_on,start_on,current_status_update,custom_fields,permalink_url",
          },
        }),
        rest.request("GET", "/status_updates", {
          query: { parent: args.parent_gid, limit: 100 },
        }),
        args.parent_type === "project"
          ? rest.request("GET", `/projects/${args.parent_gid}/task_counts`)
          : Promise.resolve(null),
      ]);
      return textResult({ parent, statuses, task_counts: taskCounts });
    }
    case "asana_get_goals":
      return textResult(
        await rest.request("GET", "/goals", {
          query: {
            workspace: args.workspace_gid,
            team: args.team_gid,
            portfolio: args.portfolio_gid,
            opt_fields: args.opt_fields,
            limit: 100,
          },
        }),
      );
    case "asana_get_goal":
      return textResult(
        await rest.request("GET", `/goals/${args.goal_gid}`, {
          query: { opt_fields: args.opt_fields },
        }),
      );
    case "asana_get_custom_fields":
      return textResult(
        await rest.request(
          "GET",
          `/workspaces/${args.workspace_gid}/custom_fields`,
          { query: { opt_fields: args.opt_fields, limit: 100 } },
        ),
      );
    case "asana_get_custom_field":
      return textResult(
        await rest.request("GET", `/custom_fields/${args.custom_field_gid}`, {
          query: {
            opt_fields:
              args.opt_fields ??
              "gid,name,description,resource_subtype,enum_options,enum_options.gid,enum_options.name,enum_options.enabled",
          },
        }),
      );
    case "asana_get_project_custom_field_settings":
      return textResult(
        await rest.request(
          "GET",
          `/projects/${args.project_gid}/custom_field_settings`,
          { query: { opt_fields: args.opt_fields, limit: 100 } },
        ),
      );
    case "asana_get_portfolio_custom_field_settings":
      return textResult(
        await rest.request(
          "GET",
          `/portfolios/${args.portfolio_gid}/custom_field_settings`,
          { query: { opt_fields: args.opt_fields, limit: 100 } },
        ),
      );
    case "asana_preview_task_changes":
      return textResult({
        dry_run: true,
        operation: args.operation,
        count: args.tasks.length,
        tasks: args.tasks,
      });
    case "asana_create_tasks_bulk":
      return textResult({
        created: await runBulk(args.tasks, (task) =>
          rest.request("POST", "/tasks", { data: task }),
        ),
      });
    case "asana_update_tasks_bulk":
      return textResult({
        updated: await runBulk<{ task_gid: string; data: Record<string, any> }>(
          args.tasks,
          (task) =>
            rest.request("PUT", `/tasks/${task.task_gid}`, { data: task.data }),
        ),
      });
    default:
      return undefined;
  }
}
