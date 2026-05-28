<img width="100" height="100" alt="AppIcon" src="https://github.com/user-attachments/assets/fae91f34-91d6-4f03-a7c6-a68ebc948fcd" />


# Apple MCP

Apple MCP is a local macOS app and MCP server for giving AI tools controlled access to Apple apps.

It includes a SwiftUI setup app for permissions and client configuration, plus a TypeScript stdio MCP server for clients like Codex, Claude Code, Claude Desktop, Raycast, and any other MCP-compatible app.

## Features

- Native macOS setup app with integration toggles and permission status.
- Calendar and Reminders access through EventKit.
- Notes, Mail, Music, and Shortcuts adapters through local macOS automation surfaces.
- Local MCP server over stdio.
- Client setup helpers for Codex and Claude.
- Safety guardrails for risky actions like sending mail, running shortcuts, and completing reminders.

## MCP Tools

Apple MCP exposes these tools:

- `apple_permissions_status`
- `apple_request_permission`
- `calendar_list_events`
- `calendar_create_event`
- `reminders_list`
- `reminders_create`
- `reminders_complete`
- `notes_search`
- `notes_read`
- `notes_create`
- `mail_search`
- `mail_read`
- `mail_create_draft`
- `mail_send_draft`
- `shortcuts_list`
- `shortcuts_run`
- `music_search`
- `music_play`
- `music_pause`

Risky tools require `confirm: true` and a short `reason`.

## Requirements

- macOS 14 or newer
- Xcode command line tools / Swift toolchain
- Node.js 20 or newer
- npm

## Build And Run

```sh
npm install
npm run build
swift build
./script/build_and_run.sh
```

The app stores local preferences at:

```text
~/.apple-apps-mcp/config.json
```

## Run The MCP Server

```sh
npm run dev:mcp
```

After building, you can register the server manually:

```sh
codex mcp add apple-apps -- node /absolute/path/to/dist/mcp/index.js
claude mcp add apple-apps -- node /absolute/path/to/dist/mcp/index.js
```

The setup app can also write or show client config for supported AI apps.

## Permissions

Calendar and Reminders use native EventKit permissions. The setup app owns the foreground permission prompt and runs a localhost-only EventKit bridge so MCP calls share the approved app context.

Notes, Mail, Music, and Shortcuts may trigger macOS Automation prompts on first use.

## Development

```sh
npm test
npm run build
swift build
./script/build_and_run.sh --verify
```

The Codex app Run button is wired through:

```text
.codex/environments/environment.toml
```
