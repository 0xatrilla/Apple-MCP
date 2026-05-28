#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { loadConfig } from "../config/config.js";
import { IntegrationId } from "../config/types.js";
import { createCalendarEvent, createReminder, completeReminder, listCalendarEvents, listReminders } from "../adapters/eventKit.js";
import { permissionsStatus, requestPermission } from "../adapters/permissions.js";
import { createNote, readNote, searchNotes } from "../adapters/notes.js";
import { createDraft, readMail, searchMail, sendDraft } from "../adapters/mail.js";
import { listShortcuts, runShortcut } from "../adapters/shortcuts.js";
import { pauseMusic, playMusic, searchMusic } from "../adapters/music.js";
import { requireConfirmation } from "../services/safety.js";

const server = new McpServer({ name: "apple-apps", version: "0.1.0" });

function jsonContent(data: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
}

async function requireEnabled(integration: IntegrationId) {
  const config = await loadConfig();
  if (!config.integrations[integration]) {
    throw new Error(`${integration} integration is disabled in the Apple Apps MCP setup app.`);
  }
}

server.registerTool("apple_permissions_status", {
  title: "Apple Permissions Status",
  description: "Show Calendar, Reminders, and automation permission status.",
  inputSchema: z.object({})
}, async () => jsonContent(await permissionsStatus()));

server.registerTool("apple_request_permission", {
  title: "Request Apple Permission",
  description: "Request Calendar or Reminders permission, or explain Automation permissions.",
  inputSchema: z.object({ target: z.enum(["calendar", "reminders", "automation"]) })
}, async ({ target }) => jsonContent(await requestPermission(target)));

server.registerTool("calendar_list_events", {
  title: "List Calendar Events",
  description: "List calendar events in a date range.",
  inputSchema: z.object({ start: z.string().optional(), end: z.string().optional() })
}, async (input) => {
  await requireEnabled("calendar");
  return jsonContent(await listCalendarEvents(input));
});

server.registerTool("calendar_create_event", {
  title: "Create Calendar Event",
  description: "Create a calendar event.",
  inputSchema: z.object({
    title: z.string(),
    start: z.string(),
    end: z.string(),
    notes: z.string().optional(),
    calendarId: z.string().optional()
  })
}, async (input) => {
  await requireEnabled("calendar");
  return jsonContent(await createCalendarEvent(input));
});

server.registerTool("reminders_list", {
  title: "List Reminders",
  description: "List reminders.",
  inputSchema: z.object({ completed: z.boolean().optional() })
}, async (input) => {
  await requireEnabled("reminders");
  return jsonContent(await listReminders(input));
});

server.registerTool("reminders_create", {
  title: "Create Reminder",
  description: "Create a reminder.",
  inputSchema: z.object({
    title: z.string(),
    notes: z.string().optional(),
    dueDate: z.string().optional(),
    calendarId: z.string().optional()
  })
}, async (input) => {
  await requireEnabled("reminders");
  return jsonContent(await createReminder(input));
});

server.registerTool("reminders_complete", {
  title: "Complete Reminder",
  description: "Complete a reminder. Requires confirmation.",
  inputSchema: z.object({ id: z.string(), confirm: z.boolean().optional(), reason: z.string().optional() })
}, async (input) => {
  await requireEnabled("reminders");
  requireConfirmation("Completing a reminder", input);
  return jsonContent(await completeReminder({ id: input.id }));
});

server.registerTool("notes_search", {
  title: "Search Notes",
  description: "Search Apple Notes.",
  inputSchema: z.object({ query: z.string().default(""), limit: z.number().int().min(1).max(50).default(10) })
}, async ({ query, limit }) => {
  await requireEnabled("notes");
  return jsonContent(await searchNotes(query, limit));
});

server.registerTool("notes_read", {
  title: "Read Note",
  description: "Read an Apple Note by id.",
  inputSchema: z.object({ id: z.string() })
}, async ({ id }) => {
  await requireEnabled("notes");
  return jsonContent(await readNote(id));
});

server.registerTool("notes_create", {
  title: "Create Note",
  description: "Create an Apple Note.",
  inputSchema: z.object({ title: z.string(), body: z.string(), folderName: z.string().optional() })
}, async ({ title, body, folderName }) => {
  await requireEnabled("notes");
  return jsonContent(await createNote(title, body, folderName));
});

server.registerTool("mail_search", {
  title: "Search Mail",
  description: "Search Apple Mail by subject or sender.",
  inputSchema: z.object({ query: z.string().default(""), limit: z.number().int().min(1).max(50).default(10) })
}, async ({ query, limit }) => {
  await requireEnabled("mail");
  return jsonContent(await searchMail(query, limit));
});

server.registerTool("mail_read", {
  title: "Read Mail",
  description: "Read a Mail message by id.",
  inputSchema: z.object({ id: z.string() })
}, async ({ id }) => {
  await requireEnabled("mail");
  return jsonContent(await readMail(id));
});

server.registerTool("mail_create_draft", {
  title: "Create Mail Draft",
  description: "Create a visible Apple Mail draft.",
  inputSchema: z.object({ to: z.array(z.string().email()), subject: z.string(), body: z.string() })
}, async ({ to, subject, body }) => {
  await requireEnabled("mail");
  return jsonContent(await createDraft(to, subject, body));
});

server.registerTool("mail_send_draft", {
  title: "Send Mail Draft",
  description: "Send an Apple Mail draft. Requires confirmation.",
  inputSchema: z.object({ id: z.string(), confirm: z.boolean().optional(), reason: z.string().optional() })
}, async (input) => {
  await requireEnabled("mail");
  requireConfirmation("Sending mail", input);
  return jsonContent(await sendDraft(input.id));
});

server.registerTool("shortcuts_list", {
  title: "List Shortcuts",
  description: "List local Apple Shortcuts.",
  inputSchema: z.object({})
}, async () => {
  await requireEnabled("shortcuts");
  return jsonContent(await listShortcuts());
});

server.registerTool("shortcuts_run", {
  title: "Run Shortcut",
  description: "Run an Apple Shortcut. Requires confirmation.",
  inputSchema: z.object({ name: z.string(), input: z.string().optional(), confirm: z.boolean().optional(), reason: z.string().optional() })
}, async (input) => {
  await requireEnabled("shortcuts");
  requireConfirmation("Running a shortcut", input);
  return jsonContent(await runShortcut(input.name, input.input));
});

server.registerTool("music_search", {
  title: "Search Music",
  description: "Search Apple Music library.",
  inputSchema: z.object({ query: z.string().default(""), limit: z.number().int().min(1).max(50).default(10) })
}, async ({ query, limit }) => {
  await requireEnabled("music");
  return jsonContent(await searchMusic(query, limit));
});

server.registerTool("music_play", {
  title: "Play Music",
  description: "Resume playback or play a track by id.",
  inputSchema: z.object({ id: z.string().optional() })
}, async ({ id }) => {
  await requireEnabled("music");
  return jsonContent(await playMusic(id));
});

server.registerTool("music_pause", {
  title: "Pause Music",
  description: "Pause Apple Music.",
  inputSchema: z.object({})
}, async () => {
  await requireEnabled("music");
  return jsonContent(await pauseMusic());
});

const transport = new StdioServerTransport();
await server.connect(transport);
