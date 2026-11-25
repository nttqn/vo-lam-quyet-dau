// One-off rewrite: `"Vietnamese %d" % x`  ->  `L.f("Vietnamese %d", x)` in
// scripts/ (dry run prints the sites; pass --write to change the files).
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const VN = /[àáảãạăắằẳẵặâấầẩẫậđèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬĐÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ]/;
const write = process.argv.includes('--write');
const lines = new Set((process.argv.find((a) => a.startsWith('--lines=')) || '--lines=').slice(8).split(',').filter(Boolean));
const only = process.argv.slice(2).filter((a) => !a.startsWith('--'));

function files(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) files(p, out);
    else if (e.name.endsWith('.gd') && !e.name.endsWith('i18n.gd')) out.push(p);
  }
  return out;
}

function skipString(src, i) {
  const q = src[i];
  let j = i + 1;
  while (j < src.length && src[j] !== q) j += src[j] === '\\' ? 2 : 1;
  return j + 1;
}

function balanced(src, i) {
  const open = src[i], close = { '(': ')', '[': ']', '{': '}' }[open];
  let depth = 0, j = i;
  while (j < src.length) {
    const c = src[j];
    if (c === '"' || c === "'") { j = skipString(src, j); continue; }
    if (c === open) depth++;
    else if (c === close) { depth--; if (depth === 0) return j + 1; }
    j++;
  }
  return -1;
}

// End of the operand right of `%` starting at i (after spaces).
function operandEnd(src, i) {
  let j = i;
  if (src[j] === '-') j++;
  if (src[j] === '[' || src[j] === '(') return balanced(src, j);
  if (src[j] === '"' || src[j] === "'") j = skipString(src, j);
  else {
    const m = /^[A-Za-z_0-9][A-Za-z_0-9]*/.exec(src.slice(j));
    if (!m) return -1;
    j += m[0].length;
  }
  for (;;) {
    if (src[j] === '.' && /[A-Za-z_]/.test(src[j + 1] || '')) {
      j++;
      j += /^[A-Za-z_0-9]*/.exec(src.slice(j))[0].length;
    } else if (src[j] === '(' || src[j] === '[') {
      j = balanced(src, j);
      if (j < 0) return -1;
    } else return j;
  }
}

let total = 0;
for (const f of files(path.join(ROOT, 'scripts'))) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  if (only.length && !only.some((o) => rel.includes(o))) continue;
  let src = fs.readFileSync(f, 'utf8');
  let out = '', i = 0, n = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === '#') { const e = src.indexOf('\n', i); const end = e < 0 ? src.length : e; out += src.slice(i, end); i = end; continue; }
    if (c === '"' && !src.startsWith('"""', i)) {
      const end = skipString(src, i);
      const lit = src.slice(i, end);
      const m = /^\s*%\s*/.exec(src.slice(end));
      const line = src.slice(src.lastIndexOf('\n', i) + 1, src.indexOf('\n', i));
      const lnNo = src.slice(0, i).split('\n').length;
      if (m && (VN.test(lit) || lines.has(`${rel}:${lnNo}`)) && !/\b(print|push_warning|push_error)\(/.test(line)) {
        const oStart = end + m[0].length;
        const oEnd = operandEnd(src, oStart);
        if (oEnd > 0) {
          const rep = `L.f(${lit}, ${src.slice(oStart, oEnd)})`;
          const ln = src.slice(0, i).split('\n').length;
          console.log(`${rel}:${ln}: ${rep.replace(/\s+/g, ' ').slice(0, 170)}`);
          out += rep;
          i = oEnd;
          n++;
          continue;
        }
        console.log(`${rel}: SKIP ${lit}`);
      }
      out += lit;
      i = end;
      continue;
    }
    out += c;
    i++;
  }
  total += n;
  if (write && n) fs.writeFileSync(f, out);
}
console.log(`${total} sites${write ? ' rewritten' : ''}`);
