import { runJxa } from "./process.js";

export async function searchMusic(query: string, limit = 10) {
  const script = `
function run(argv) {
  const query = (argv[0] || "").toLowerCase();
  const limit = Number(argv[1] || "10");
  const Music = Application("Music");
  const out = [];
  for (const track of Music.libraryPlaylists[0].tracks()) {
    const name = track.name() || "";
    const artist = track.artist() || "";
    if (!query || name.toLowerCase().includes(query) || artist.toLowerCase().includes(query)) {
      out.push({ id: track.id(), name, artist, album: track.album() || "" });
    }
    if (out.length >= limit) return JSON.stringify(out);
  }
  return JSON.stringify(out);
}`;
  return JSON.parse(await runJxa(script, [query, String(limit)]));
}

export async function playMusic(id?: string) {
  const script = `
function run(argv) {
  const id = argv[0];
  const Music = Application("Music");
  if (id) {
    for (const track of Music.libraryPlaylists[0].tracks()) {
      if (String(track.id()) === id) {
        track.play();
        return JSON.stringify({ playing: true, id });
      }
    }
    throw new Error("Track not found");
  }
  Music.play();
  return JSON.stringify({ playing: true });
}`;
  return JSON.parse(await runJxa(script, [id ?? ""]));
}

export async function pauseMusic() {
  const script = `
function run() {
  Application("Music").pause();
  return JSON.stringify({ playing: false });
}`;
  return JSON.parse(await runJxa(script));
}
