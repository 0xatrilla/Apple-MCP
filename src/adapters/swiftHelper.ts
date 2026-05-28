import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { runCommand } from "./process.js";

const here = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(here, "..", "..");
const helperAppExecutable = join(projectRoot, "dist", "AppleAppsHelper.app", "Contents", "MacOS", "AppleAppsHelper");
const bundledHelper = join(projectRoot, "dist", "AppleAppsControl.app", "Contents", "MacOS", "AppleAppsHelper");
const releaseHelper = join(projectRoot, ".build", "release", "AppleAppsHelper");
const debugHelper = join(projectRoot, ".build", "debug", "AppleAppsHelper");
const bridgeCommands = new Set([
  "permissions-status",
  "request-permission",
  "calendar-list-events",
  "calendar-create-event",
  "reminders-list",
  "reminders-create",
  "reminders-complete"
]);

export async function runSwiftHelper<TInput extends object, TOutput = unknown>(
  command: string,
  input: TInput
): Promise<TOutput> {
  const payload = JSON.stringify(input);
  if (bridgeCommands.has(command)) {
    const bridgeResult = await tryBridge<TOutput>(command, payload);
    if (bridgeResult.ok) {
      return bridgeResult.value;
    }
  }

  const helper = process.env.APPLE_APPS_HELPER
    ?? [helperAppExecutable, bundledHelper, releaseHelper, debugHelper].find((candidate) => existsSync(candidate));

  if (helper && existsSync(helper)) {
    const result = await runCommand(helper, [command], payload);
    return JSON.parse(result.stdout) as TOutput;
  }

  const result = await runCommand("swift", ["run", "AppleAppsHelper", command], payload);
  return JSON.parse(result.stdout) as TOutput;
}

async function tryBridge<TOutput>(command: string, payload: string): Promise<
  { ok: true; value: TOutput } | { ok: false }
> {
  try {
    const response = await fetch(`http://127.0.0.1:17373/${command}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: payload,
      signal: AbortSignal.timeout(1200)
    });
    const text = await response.text();
    const parsed = text ? JSON.parse(text) : {};
    if (!response.ok) {
      throw new Error(parsed.error ?? `Bridge returned HTTP ${response.status}`);
    }
    return { ok: true, value: parsed as TOutput };
  } catch {
    return { ok: false };
  }
}
