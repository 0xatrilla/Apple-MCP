export type IntegrationId = "calendar" | "reminders" | "notes" | "mail" | "shortcuts" | "music";

export type PreferredClient = "codex" | "claude" | "raycast" | "manual";

export interface AppleAppsConfig {
  preferredClient: PreferredClient;
  onboardingComplete: boolean;
  integrations: Record<IntegrationId, boolean>;
}

export const integrationIds: IntegrationId[] = [
  "calendar",
  "reminders",
  "notes",
  "mail",
  "shortcuts",
  "music"
];

export const defaultConfig: AppleAppsConfig = {
  preferredClient: "codex",
  onboardingComplete: false,
  integrations: {
    calendar: true,
    reminders: true,
    notes: true,
    mail: true,
    shortcuts: true,
    music: true
  }
};
