// Funnel report: reads the funnel/{step} counters (scripts/data/funnel.gd)
// and prints them in play order with the share of installs that got there.
//   node tools/funnel_report.mjs
// Signs in as a throwaway anonymous user (the rules let any signed-in user read).
import { readFileSync } from "node:fs";

const cfg = JSON.parse(readFileSync(new URL("../cloud_config.json", import.meta.url), "utf8"));
const key = cfg.api_key, project = cfg.project_id;

const auth = await (await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${key}`, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ returnSecureToken: true }),
})).json();
if (!auth.idToken) { console.error("sign-in failed", auth); process.exit(1); }

const rows = [];
let page = "";
do {
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/funnel?pageSize=300${page ? "&pageToken=" + page : ""}`;
  const r = await (await fetch(url, { headers: { Authorization: `Bearer ${auth.idToken}` } })).json();
  if (r.error) { console.error(r.error); process.exit(1); }
  for (const d of r.documents ?? []) {
    rows.push([d.name.split("/").pop(), Number(d.fields?.n?.integerValue ?? 0)]);
  }
  page = r.nextPageToken ?? "";
} while (page);

// the throwaway account is deleted again
await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${key}`, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ idToken: auth.idToken }),
});

// play order: install, hero, fights, levels, regions, side modes, days; events last
const order = (id) => {
  const m = (re) => id.match(re);
  let x;
  if (id === "f_install") return 0;
  if (id === "f_hero") return 1;
  if ((x = m(/^f_(fight|win)(\d+)$/))) return 2 + Number(x[2]) / 1000;
  if ((x = m(/^f_lv(\d+)$/))) return 3 + Number(x[1]) / 100;
  if ((x = m(/^f_r(\d+)s(\d+)$/))) return 4 + Number(x[1]) / 10 + Number(x[2]) / 100;
  if ((x = m(/^f_day(\d+)$/))) return 6 + Number(x[1]) / 100;
  if (id.startsWith("f_")) return 5;
  return 9;
};
rows.sort((a, b) => order(a[0]) - order(b[0]) || b[1] - a[1] || a[0].localeCompare(b[0]));
const base = rows.find((r) => r[0] === "f_install")?.[1] || rows.find((r) => r[0] === "f_hero")?.[1] || 1;
console.log("step".padEnd(22), "players".padStart(8), "  of installs");
for (const [id, n] of rows) {
  const pct = id.startsWith("f_") ? `${((100 * n) / base).toFixed(1).padStart(6)}%` : "  (events)";
  console.log(id.padEnd(22), String(n).padStart(8), " ", pct);
}
