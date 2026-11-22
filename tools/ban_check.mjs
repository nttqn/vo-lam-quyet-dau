// What a uid still has on the shared boards (rank, this week's Tỉ Võ, today's
// Boss Thế Giới), and the console paths to delete. The ban itself is the doc
// ban/{uid} you create in the console ({why: string, until: timestamp}, both
// optional); only its owner can read it, so this tool can't show it.
//   node tools/ban_check.mjs <uid>
import { readFileSync } from "node:fs";

const uid = process.argv[2];
if (!uid) { console.error("usage: node tools/ban_check.mjs <uid>"); process.exit(1); }
const cfg = JSON.parse(readFileSync(new URL("../cloud_config.json", import.meta.url), "utf8"));
const key = cfg.api_key, project = cfg.project_id;
const auth = await (await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${key}`, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ returnSecureToken: true }),
})).json();
if (!auth.idToken) { console.error("sign-in failed", auth); process.exit(1); }
const H = { Authorization: `Bearer ${auth.idToken}` };
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/`;
const plain = f => Object.fromEntries(Object.entries(f ?? {}).map(([k, v]) => [k, Object.values(v)[0]]));

// same week id as Duel.season(): Monday-based, counted from Jan 1 of the Monday's year
const now = new Date();
const mondayMs = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()) - ((now.getUTCDay() + 6) % 7) * 86400000;
const monday = new Date(mondayMs);
const week = Math.floor((mondayMs - Date.UTC(monday.getUTCFullYear(), 0, 1)) / (7 * 86400000)) + 1;
const season = `duel_${monday.getUTCFullYear()}w${String(week).padStart(2, "0")}`;
const today = `wb_${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}${String(now.getDate()).padStart(2, "0")}`;

const paths = [...[0, 1, 2, 3, 4, 5].map(i => `rank/${uid}_${i}`), `${season}/${uid}`, ...[0, 1, 2, 3, 4, 5].map(i => `${today}/${uid}_${i}`)];
let found = 0;
for (const p of paths) {
  const r = await fetch(base + p, { headers: H });
  if (r.status === 200) {
    const d = plain((await r.json()).fields);
    found++;
    console.log(`FOUND ${p}  name=${JSON.stringify(d.name)} level=${d.level ?? "-"} power=${d.power ?? "-"} dmg=${d.dmg ?? "-"}`);
  } else if (r.status !== 404) {
    console.log(`?     ${p}  HTTP ${r.status}`);
  }
}
console.log(found ? `${found} doc(s) to delete in the console (1.3.1+ clients delete their own on the next launch).` : "Nothing on the boards.");
await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${key}`, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ idToken: auth.idToken }),
});
