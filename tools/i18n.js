// Localization tables for scripts/i18n.gd (class L).
//
//   node tools/i18n.js sync            collect every Vietnamese string literal
//                                      in scripts/ into i18n/<lang>.json
//                                      (keeps translations, drops unused keys,
//                                      prefills from Kiếm Hiệp's tables)
//   node tools/i18n.js missing <lang> [n]   print up to n untranslated keys as JSON
//   node tools/i18n.js put <lang> <file.json>   merge {key: translation} into a table
//   node tools/i18n.js check           placeholders (%s %d %.1f…) match in every table
//
// A key is a literal (or literals joined by +) with Vietnamese letters, or
// one listed in EXTRA (diacritic-free text shown to players).
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const LANGS = ['zh_Hant', 'ko', 'en'];
const KH = path.join(ROOT, '..', 'kiem-hiep-app', 'assets', 'i18n');
const VN = /[àáảãạăắằẳẵặâấầẩẫậđèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬĐÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ]/;
const EXTRA = require('./i18n_extra.json');

function files(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) files(p, out);
    else if (e.name.endsWith('.gd')) out.push(p);
  }
  return out;
}

function unescape(s) {
  return s.replace(/\\(.)/g, (_, c) => ({ n: '\n', t: '\t', r: '\r', '"': '"', "'": "'", '\\': '\\' }[c] ?? '\\' + c));
}

// String literals of one file, adjacent `"a" + "b"` joined, comments skipped.
function literals(src) {
  const out = [];
  let i = 0, line = 1;
  let chain = null, chainEnd = -1;
  const flush = () => { if (chain) out.push(chain); chain = null; };
  while (i < src.length) {
    const c = src[i];
    if (c === '\n') { line++; i++; continue; }
    if (c === '#') { while (i < src.length && src[i] !== '\n') i++; continue; }
    if (c === '"' || c === "'") {
      const triple = src.startsWith(c.repeat(3), i);
      const q = triple ? c.repeat(3) : c;
      let j = i + q.length, raw = '';
      while (j < src.length && !src.startsWith(q, j)) {
        if (src[j] === '\\') { raw += src[j] + src[j + 1]; j += 2; continue; }
        if (src[j] === '\n') line++;
        raw += src[j++];
      }
      const val = unescape(raw);
      const between = chain ? src.slice(chainEnd, i) : '';
      const lineText = src.slice(src.lastIndexOf('\n', i) + 1, src.indexOf('\n', i) < 0 ? src.length : src.indexOf('\n', i));
      if (chain && /^[\s\\]*\+[\s\\]*$/.test(between)) {
        chain.val += val;
      } else {
        flush();
        chain = { val, line, lineText };
      }
      i = j + q.length;
      chainEnd = i;
      continue;
    }
    if (chain && !/[\s\\+]/.test(c)) flush();
    i++;
  }
  flush();
  return out;
}

function collect() {
  const keys = new Map();
  for (const f of files(path.join(ROOT, 'scripts'))) {
    const rel = path.relative(ROOT, f).replace(/\\/g, '/');
    for (const l of literals(fs.readFileSync(f, 'utf8'))) {
      if (!VN.test(l.val) && !EXTRA.includes(l.val)) continue;
      if (/^\s*"[^"]+": 1,/.test(l.lineText)) continue;            // chat SWEARS list
      if (/^[a-zđăâêôơư]\S{0,5}$/.test(l.val) && /^[a-zđăâêôơư]/.test(l.val) && l.val === l.val.toLowerCase() && /_VN_ROWS|^\s*"/.test(l.lineText) && l.val.length <= 6 && !/ /.test(l.val) && /^.[àáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ]{5}$|^đ$/.test(l.val)) continue;   // chat tone tables
      if (/\b(print|push_warning|push_error|printerr)\(/.test(l.lineText)) continue;
      if (!keys.has(l.val)) keys.set(l.val, `${rel}:${l.line}`);
    }
  }
  for (const e of EXTRA) if (!keys.has(e)) keys.set(e, 'extra');
  return keys;
}

const tablePath = (lang) => path.join(ROOT, 'i18n', `${lang}.json`);
const readTable = (p) => (fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : {});
const writeTable = (lang, t) => fs.writeFileSync(tablePath(lang), JSON.stringify(t, null, 1) + '\n');

const PH = /%[-+0#]*\d*(?:\.\d+)?[sdfxXc%]/g;
const ph = (s) => (s.match(PH) || []).filter((p) => p !== '%%').join(' ');

const [cmd, a1, a2] = process.argv.slice(2);
if (cmd === 'sync') {
  const keys = collect();
  fs.mkdirSync(path.join(ROOT, 'i18n'), { recursive: true });
  for (const lang of LANGS) {
    const old = readTable(tablePath(lang));
    const kh = readTable(path.join(KH, `${lang}.json`));
    const t = {};
    let filled = 0, kept = 0;
    for (const k of keys.keys()) {
      if (old[k]) { t[k] = old[k]; kept++; }
      else if (kh[k] && ph(kh[k]) === ph(k)) { t[k] = kh[k]; filled++; }
      else t[k] = '';
    }
    writeTable(lang, t);
    const missing = Object.values(t).filter((v) => !v).length;
    console.log(`${lang}: ${keys.size} keys, ${kept} kept, ${filled} from Kiếm Hiệp, ${missing} missing`);
  }
} else if (cmd === 'missing') {
  const t = readTable(tablePath(a1));
  const n = Number(a2 || 1e9);
  const out = {};
  for (const [k, v] of Object.entries(t)) if (!v && Object.keys(out).length < n) out[k] = '';
  console.log(JSON.stringify(out, null, 1));
} else if (cmd === 'put') {
  const t = readTable(tablePath(a1));
  const add = JSON.parse(fs.readFileSync(a2, 'utf8'));
  let n = 0, unknown = [];
  for (const [k, v] of Object.entries(add)) {
    if (!(k in t)) { unknown.push(k); continue; }
    t[k] = v; n++;
  }
  writeTable(a1, t);
  console.log(`${a1}: put ${n}` + (unknown.length ? `, ${unknown.length} unknown keys:\n` + unknown.join('\n') : ''));
} else if (cmd === "put3") {
  // {key: [zh_Hant, ko, en]}
  const add = JSON.parse(fs.readFileSync(a1, "utf8"));
  LANGS.forEach((lang, li) => {
    const t = readTable(tablePath(lang));
    let n = 0; const unknown = [];
    for (const [k, v] of Object.entries(add)) {
      if (!(k in t)) { unknown.push(k); continue; }
      if (v[li]) { t[k] = v[li]; n++; }
    }
    writeTable(lang, t);
    console.log(lang + ': put ' + n + (unknown.length && li === 0 ? ', unknown:\n' + unknown.join('\n') : ''));
  });
} else if (cmd === 'check') {
  let bad = 0;
  for (const lang of LANGS) {
    for (const [k, v] of Object.entries(readTable(tablePath(lang)))) {
      if (v && ph(v) !== ph(k)) { console.log(`${lang}: ${JSON.stringify(k)} -> ${JSON.stringify(v)}`); bad++; }
    }
  }
  console.log(bad ? `${bad} placeholder mismatches` : 'placeholders ok');
  process.exit(bad ? 1 : 0);
} else if (cmd === 'where') {
  for (const [k, w] of collect()) if (k.includes(a1)) console.log(w, JSON.stringify(k));
} else {
  console.log('usage: sync | missing <lang> [n] | put <lang> <file> | check | where <text>');
}
