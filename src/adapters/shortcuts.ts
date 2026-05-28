import { runCommand } from "./process.js";

export async function listShortcuts() {
  const result = await runCommand("/usr/bin/shortcuts", ["list"]);
  return result.stdout.split("\n").map((line) => line.trim()).filter(Boolean);
}

export async function runShortcut(name: string, input?: string) {
  const args = ["run", name];
  if (input) {
    args.push("--input-path", "-");
  }
  const result = await runCommand("/usr/bin/shortcuts", args, input);
  return { name, stdout: result.stdout.trim(), stderr: result.stderr.trim() };
}
