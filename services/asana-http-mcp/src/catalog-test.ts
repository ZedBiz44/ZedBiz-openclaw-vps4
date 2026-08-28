import { advancedTools } from "./advanced-tools.js";
import { list_of_tools } from "./tool-handler.js";

const standard = list_of_tools.map((tool) => tool.name);
const advanced = [...standard, ...advancedTools.map((tool) => tool.name)];
const requiredStandard = [
  "asana_get_user",
  "asana_create_task",
  "asana_create_subtask",
  "asana_create_section",
  "asana_create_project_status",
  "asana_create_project_brief",
  "asana_upload_attachment",
  "asana_create_tag_for_workspace",
  "asana_add_task_dependencies",
  "asana_remove_task_dependencies",
  "asana_update_project",
  "asana_get_portfolio_items",
];
const requiredAdvanced = [
  "asana_list_teams",
  "asana_create_team",
  "asana_create_portfolio",
  "asana_add_portfolio_item",
  "asana_create_custom_field",
  "asana_create_goal",
  "asana_create_webhook",
  "asana_trigger_rule",
  "asana_api_request",
];

function assertCatalog(name: string, tools: string[], required: string[]): void {
  const duplicates = tools.filter(
    (tool, index, names) => names.indexOf(tool) !== index,
  );
  if (duplicates.length) {
    throw new Error(`${name} duplicate tools: ${duplicates.join(", ")}`);
  }
  const missing = required.filter((tool) => !tools.includes(tool));
  if (missing.length) {
    throw new Error(`${name} missing required tools: ${missing.join(", ")}`);
  }
}

assertCatalog("Standard", standard, requiredStandard);
assertCatalog("Advanced", advanced, [...requiredStandard, ...requiredAdvanced]);

console.log(
  JSON.stringify({
    ok: true,
    standardTools: standard.length,
    advancedTools: advanced.length,
    advancedNamedAdditions: advancedTools.length,
  }),
);
