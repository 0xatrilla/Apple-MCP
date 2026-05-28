import { runSwiftHelper } from "./swiftHelper.js";

export interface DateRangeInput {
  start?: string;
  end?: string;
}

export function listCalendarEvents(input: DateRangeInput) {
  return runSwiftHelper("calendar-list-events", input);
}

export function createCalendarEvent(input: {
  title: string;
  start: string;
  end: string;
  notes?: string;
  calendarId?: string;
}) {
  return runSwiftHelper("calendar-create-event", input);
}

export function listReminders(input: { completed?: boolean }) {
  return runSwiftHelper("reminders-list", input);
}

export function createReminder(input: {
  title: string;
  notes?: string;
  dueDate?: string;
  calendarId?: string;
}) {
  return runSwiftHelper("reminders-create", input);
}

export function completeReminder(input: { id: string }) {
  return runSwiftHelper("reminders-complete", input);
}
