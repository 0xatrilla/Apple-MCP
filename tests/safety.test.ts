import { describe, expect, it } from "vitest";
import { requireConfirmation } from "../src/services/safety.js";
import { normalizeConfig } from "../src/config/config.js";

describe("requireConfirmation", () => {
  it("rejects risky actions without confirmation", () => {
    expect(() => requireConfirmation("Sending mail", {})).toThrow(/requires confirm/);
  });

  it("rejects risky actions without a reason", () => {
    expect(() => requireConfirmation("Running a shortcut", { confirm: true })).toThrow(/requires confirm/);
  });

  it("allows confirmed actions with a reason", () => {
    expect(() => requireConfirmation("Completing a reminder", { confirm: true, reason: "User asked" })).not.toThrow();
  });
});

describe("normalizeConfig", () => {
  it("fills missing integration defaults", () => {
    const config = normalizeConfig({ integrations: { notes: false } as never });
    expect(config.integrations.notes).toBe(false);
    expect(config.integrations.calendar).toBe(true);
  });
});
