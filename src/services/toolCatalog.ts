import { IntegrationId } from "../config/types.js";

export interface ToolDescriptor {
  name: string;
  integration: IntegrationId | "permissions";
  risky?: boolean;
}

export const toolCatalog: ToolDescriptor[] = [
  { name: "apple_permissions_status", integration: "permissions" },
  { name: "apple_request_permission", integration: "permissions" },
  { name: "calendar_list_events", integration: "calendar" },
  { name: "calendar_create_event", integration: "calendar" },
  { name: "reminders_list", integration: "reminders" },
  { name: "reminders_create", integration: "reminders" },
  { name: "reminders_complete", integration: "reminders", risky: true },
  { name: "notes_search", integration: "notes" },
  { name: "notes_read", integration: "notes" },
  { name: "notes_create", integration: "notes" },
  { name: "mail_search", integration: "mail" },
  { name: "mail_read", integration: "mail" },
  { name: "mail_create_draft", integration: "mail" },
  { name: "mail_send_draft", integration: "mail", risky: true },
  { name: "shortcuts_list", integration: "shortcuts" },
  { name: "shortcuts_run", integration: "shortcuts", risky: true },
  { name: "music_search", integration: "music" },
  { name: "music_play", integration: "music" },
  { name: "music_pause", integration: "music" }
];

export function countToolsFor(integration: IntegrationId): number {
  return toolCatalog.filter((tool) => tool.integration === integration).length;
}
