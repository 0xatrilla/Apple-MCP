import { runSwiftHelper } from "./swiftHelper.js";

export type PermissionTarget = "calendar" | "reminders" | "automation";

export async function permissionsStatus() {
  return runSwiftHelper("permissions-status", {});
}

export async function requestPermission(target: PermissionTarget) {
  if (target === "automation") {
    return {
      target,
      status: "requires_app_prompt",
      message: "Automation permissions are requested by macOS the first time Notes, Mail, Music, or Shortcuts automation runs."
    };
  }
  return runSwiftHelper("request-permission", { target });
}
