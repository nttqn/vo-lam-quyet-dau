// App Review demo account: signs up (or signs in) an email/password account on
// the game's Firebase project and uploads a save as its cloud slot 2 (Ô lưu 3,
// so it never clashes with a hero the reviewer made as a guest), in the
// same shape Cloud._upload writes. The reviewer signs in from the title screen
// (Tài khoản → Đăng nhập) and the hero is pulled down.
//   node tools/review_demo.mjs <email> <password> <save.json>
// Make the save with tools/review_demo.gd. Keep the password out of the repo.
import fs from 'fs';

const [email, password, savePath] = process.argv.slice(2);
if (!savePath) throw new Error('usage: node tools/review_demo.mjs <email> <password> <save.json>');
const cfg = JSON.parse(fs.readFileSync(new URL('../cloud_config.json', import.meta.url)));
const KEY = cfg.api_key;
const auth = (m) => `https://identitytoolkit.googleapis.com/v1/accounts:${m}?key=${KEY}`;
const post = async (url, body) => {
  const r = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  return { code: r.status, body: await r.json() };
};

let r = await post(auth('signUp'), { email, password, returnSecureToken: true });
if (r.code !== 200) {
  const why = r.body?.error?.message || '';
  if (!why.startsWith('EMAIL_EXISTS')) throw new Error('signUp: ' + why);
  r = await post(auth('signInWithPassword'), { email, password, returnSecureToken: true });
  if (r.code !== 200) throw new Error('signIn: ' + (r.body?.error?.message || r.code));
  console.log('account exists, signed in');
} else {
  console.log('account created');
}
const { idToken, localId } = r.body;

const save = JSON.parse(fs.readFileSync(savePath, 'utf8'));
save.saved_at = Date.now() / 1000;
const doc = `https://firestore.googleapis.com/v1/projects/${cfg.project_id}/databases/(default)/documents/players/${localId}/slots/2`;
const fields = {
  data: { stringValue: JSON.stringify(save) },
  saved_at: { doubleValue: save.saved_at },
  name: { stringValue: String(save.name) },
  sect: { stringValue: String(save.sect) },
  level: { integerValue: String(save.level) },
};
const w = await fetch(doc, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + idToken }, body: JSON.stringify({ fields }) });
if (w.status !== 200) throw new Error('upload: HTTP ' + w.status + ' ' + await w.text());
console.log('slot 2 (Ô lưu 3) uploaded: %s, level %d (uid %s…)', save.name, save.level, localId.slice(0, 6));
