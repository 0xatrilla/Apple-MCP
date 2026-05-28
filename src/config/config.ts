import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { AppleAppsConfig, defaultConfig, integrationIds } from "./types.js";

export const configPath = process.env.APPLE_APPS_MCP_CONFIG
  ?? join(homedir(), ".apple-apps-mcp", "config.json");

export async function loadConfig(): Promise<AppleAppsConfig> {
  try {
    const raw = await readFile(configPath, "utf8");
    const parsed = JSON.parse(raw) as Partial<AppleAppsConfig>;
    return normalizeConfig(parsed);
  } catch (error: unknown) {
    if (isNodeError(error) && error.code === "ENOENT") {
      await saveConfig(defaultConfig);
      return defaultConfig;
    }
    throw error;
  }
}

export async function saveConfig(config: AppleAppsConfig): Promise<void> {
  await mkdir(dirname(configPath), { recursive: true });
  await writeFile(configPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

export function normalizeConfig(config: Partial<AppleAppsConfig>): AppleAppsConfig {
  const integrations = { ...defaultConfig.integrations };
  for (const id of integrationIds) {
    if (typeof config.integrations?.[id] === "boolean") {
      integrations[id] = config.integrations[id];
    }
  }

  return {
    preferredClient: config.preferredClient ?? defaultConfig.preferredClient,
    onboardingComplete: config.onboardingComplete ?? defaultConfig.onboardingComplete,
    integrations
  };
}

function isNodeError(error: unknown): error is NodeJS.ErrnoException {
  return typeof error === "object" && error !== null && "code" in error;
}
