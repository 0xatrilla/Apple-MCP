import { runJxa } from "./process.js";

export async function searchNotes(query: string, limit = 10) {
  const script = `
function run(argv) {
  const query = (argv[0] || "").toLowerCase();
  const limit = Number(argv[1] || "10");
  const Notes = Application("Notes");
  const matches = [];
  for (const account of Notes.accounts()) {
    for (const folder of account.folders()) {
      for (const note of folder.notes()) {
        const name = note.name();
        const body = note.body();
        if (!query || name.toLowerCase().includes(query) || body.toLowerCase().includes(query)) {
          matches.push({ id: note.id(), title: name, folder: folder.name(), snippet: body.replace(/<[^>]+>/g, " ").slice(0, 240) });
        }
        if (matches.length >= limit) return JSON.stringify(matches);
      }
    }
  }
  return JSON.stringify(matches);
}`;
  return JSON.parse(await runJxa(script, [query, String(limit)]));
}

export async function readNote(id: string) {
  const script = `
function run(argv) {
  const target = argv[0];
  const Notes = Application("Notes");
  for (const account of Notes.accounts()) {
    for (const folder of account.folders()) {
      for (const note of folder.notes()) {
        if (note.id() === target) return JSON.stringify({ id: note.id(), title: note.name(), folder: folder.name(), body: note.body() });
      }
    }
  }
  throw new Error("Note not found");
}`;
  return JSON.parse(await runJxa(script, [id]));
}

export async function createNote(title: string, body: string, folderName?: string) {
  const script = `
function run(argv) {
  const title = argv[0];
  const body = argv[1];
  const folderName = argv[2] || "Notes";
  const Notes = Application("Notes");
  const account = Notes.defaultAccount();
  let folder = account.folders.byName(folderName);
  try { folder.name(); } catch (_) { folder = account.folders[0]; }
  const note = Notes.Note({ name: title, body });
  folder.notes.push(note);
  return JSON.stringify({ id: note.id(), title: note.name(), folder: folder.name() });
}`;
  return JSON.parse(await runJxa(script, [title, body, folderName ?? ""]));
}
