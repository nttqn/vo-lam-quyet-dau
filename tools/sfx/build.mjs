// Builds the fight sound effects in assets/audio/ from real CC0 recordings in
// assets_src/audio/ (see assets_src/audio/CREDITS.md).
//   cd tools/sfx && npm install && node build.mjs
// Each output is a recipe of layers: source file, trim, speed (pitch), filters,
// gain and delay. The base name's variants (hit_slash_1, _2, ...) are picked at
// random by Game.sfx. To swap a sound, edit its recipe and rebuild.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { load } from './load.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const SRC = path.join(ROOT, 'assets_src/audio');
const OUT = path.join(ROOT, 'assets/audio');
const SR = 44100;

const cache = new Map();
async function src(name) {
  if (!cache.has(name)) {
    const { x, sr } = await load(path.join(SRC, name));
    cache.set(name, resample(x, sr / SR));
  }
  return cache.get(name);
}

// ------------------------------------------------------------- DSP
function resample(x, ratio) { // ratio > 1 = faster / higher
  if (Math.abs(ratio - 1) < 1e-6) return Float32Array.from(x);
  const n = Math.floor(x.length / ratio), y = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i * ratio, k = Math.floor(t), f = t - k;
    y[i] = (x[k] ?? 0) * (1 - f) + (x[k + 1] ?? 0) * f;
  }
  return y;
}
function peak(x) { let p = 0; for (const v of x) p = Math.max(p, Math.abs(v)); return p; }
/** Index where the sound starts (first 2 ms window within thresh dB of the peak). */
function onset(x, thresh = -30) {
  const p = peak(x) + 1e-9, w = Math.floor(SR * 0.002);
  for (let i = 0; i + w < x.length; i += w) {
    let e = 0; for (let j = 0; j < w; j++) e = Math.max(e, Math.abs(x[i + j]));
    if (20 * Math.log10(e / p) > thresh) return Math.max(0, i - w);
  }
  return 0;
}
function lowpass(x, hz) {
  const a = 1 - Math.exp(-2 * Math.PI * hz / SR); let s = 0; const y = new Float32Array(x.length);
  for (let i = 0; i < x.length; i++) { s += a * (x[i] - s); y[i] = s; }
  return y;
}
function highpass(x, hz) { const l = lowpass(x, hz); return x.map((v, i) => v - l[i]); }
function fade(x, inS, outS) {
  const a = Math.floor(inS * SR), b = Math.floor(outS * SR), n = x.length;
  for (let i = 0; i < Math.min(a, n); i++) x[i] *= i / a;
  for (let i = 0; i < Math.min(b, n); i++) x[n - 1 - i] *= i / b;
  return x;
}

/** One layer: {f, at (s, onset-relative start), len (s), speed, lp, hp, gain, delay (s), fade (s)} */
async function layer(l) {
  let x = await src(l.f);
  const st = (l.at !== undefined ? Math.floor(l.at * SR) : onset(x, l.thresh ?? -30));
  x = x.slice(st, l.len ? st + Math.floor(l.len * SR / (l.speed ?? 1)) : undefined);
  x = resample(x, l.speed ?? 1);
  if (l.hp) x = highpass(x, l.hp);
  if (l.lp) x = lowpass(lowpass(x, l.lp), l.lp);
  fade(x, 0.002, l.fade ?? Math.min(0.08, x.length / SR * 0.4));
  const p = peak(x) + 1e-9, g = (l.gain ?? 1) / p; // layers are peak-normalised, then weighted
  const d = Math.floor((l.delay ?? 0) * SR), y = new Float32Array(x.length + d);
  for (let i = 0; i < x.length; i++) y[i + d] = x[i] * g;
  return y;
}
async function build(layers, peakOut) {
  const ys = await Promise.all(layers.map(layer));
  const n = Math.max(...ys.map((y) => y.length)), out = new Float32Array(n);
  for (const y of ys) for (let i = 0; i < y.length; i++) out[i] += y[i];
  // trim the silent tail, short fade, normalise
  const p = peak(out) + 1e-9; let end = n;
  while (end > SR * 0.05 && Math.abs(out[end - 1]) < p * 0.003) end--;
  const z = fade(out.slice(0, end), 0, 0.01);
  for (let i = 0; i < z.length; i++) z[i] *= peakOut / p;
  return z;
}
function writeWav(file, x) {
  const b = Buffer.alloc(44 + x.length * 2);
  b.write('RIFF', 0); b.writeUInt32LE(36 + x.length * 2, 4); b.write('WAVE', 8); b.write('fmt ', 12);
  b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22); b.writeUInt32LE(SR, 24);
  b.writeUInt32LE(SR * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34); b.write('data', 36);
  b.writeUInt32LE(x.length * 2, 40);
  for (let i = 0; i < x.length; i++) b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, x[i])) * 32767), 44 + i * 2);
  fs.writeFileSync(file, b);
}

// ------------------------------------------------------------- recipes
const SW = (n) => `swishes/swish-${n}.wav`;
const IM = (n) => `impact/impact.${n}.ogg`;
const C = (n) => `cc0_100/${n}.ogg`;
const K = (n) => `kenney_rpg/${n}.ogg`;
const VM = (n) => `voice_m/${n}.wav`;

const R = {};
// --- weapon swings (whooshes). Blade = thin and quick, staff = deep "vù", body = cloth + air.
[1, 10, 11, 6, 9].forEach((n, i) => R[`swing_blade_${i + 1}`] = [[{ f: SW(n), hp: 400 }], 0.55]);
R.swing_light_1 = [[{ f: SW(2), speed: 1.2, hp: 600 }], 0.45];
R.swing_light_2 = [[{ f: SW(10), speed: 1.25, hp: 600 }], 0.45];
R.swing_light_3 = [[{ f: 'rpg_battle/swing2.wav', speed: 1.15, hp: 600 }], 0.45];
[3, 4, 7].forEach((n, i) => R[`swing_staff_${i + 1}`] = [[{ f: SW(n), speed: 0.72, lp: 3500 }], 0.6]);
[[5, 'cloth2'], [8, 'cloth2'], [9, 'cloth2']].forEach(([n, c], i) => R[`swing_body_${i + 1}`] =
  [[{ f: SW(n), speed: 0.85, lp: 2600 }, { f: K(c), len: 0.15, gain: 0.35 }], 0.4]);

// --- hits on the body
// blade: sharp slice + flesh thud + a short ring of steel
[['knifeSlice2', 5, 'footstep08'], ['knifeSlice', 6, 'footstep01'], ['knifeSlice2', 8, 'footstep00'], ['knifeSlice', 5, 'footstep08']]
  .forEach(([s, w, t], i) => R[`hit_slash_${i + 1}`] = [[
    { f: K(s), len: 0.28, gain: 0.8, hp: 900 },
    { f: K(t), speed: 0.75, lp: 1800, gain: 0.85 },
    { f: `sword/sword.${w}.ogg`, len: 0.16, gain: 0.3, hp: 2500 },
  ], 0.9]);
// staff: wooden knock + body thud
[['wooden_01', 'slam_04'], ['wooden_02', 'hit_03'], ['wooden_03', 'slam_04']].forEach(([w, t], i) => R[`hit_blunt_${i + 1}`] = [[
  { f: C(w), len: 0.25, gain: 0.75 },
  { f: C(t), lp: 1600, gain: 0.9 },
], 0.9]);
// fist: punchy close thuds
[[4, 'footstep08'], [6, 'footstep01'], [8, 'footstep00'], [5, 'footstep08']].forEach(([m, t], i) => R[`hit_punch_${i + 1}`] = [[
  { f: IM(m), len: 0.18, lp: 3200 },
  { f: K(t), speed: 0.8, lp: 1500, gain: 0.6 },
], 0.85]);
// kick: heavier, lower
[['slam_02', 7], ['slam_03', 10], ['slam_02', 8]].forEach(([s, m], i) => R[`hit_kick_${i + 1}`] = [[
  { f: C(s), len: 0.3, lp: 2200 },
  { f: IM(m), len: 0.2, speed: 0.85, lp: 2400, gain: 0.8 },
], 0.9]);
// palm (chưởng): slap + burst of air
[[1, 7], [9, 3]].forEach(([m, s], i) => R[`hit_palm_${i + 1}`] = [[
  { f: IM(m), len: 0.2, lp: 4000 },
  { f: SW(s), speed: 0.65, lp: 2000, gain: 0.45 },
], 0.85]);
// heavy layer added under strong / skill hits: deep body thump
R.hit_heavy_1 = [[{ f: C('explosion'), speed: 0.7, lp: 900 }, { f: C('slam_03'), lp: 1500, gain: 0.8 }], 0.9];
R.hit_heavy_2 = [[{ f: C('explosion'), speed: 0.62, lp: 800 }, { f: C('slam_06'), lp: 1500, gain: 0.7 }], 0.9];

// --- blocks: steel on steel / wood / forearm
[2, 5, 7, 8].forEach((n, i) => R[`block_metal_${i + 1}`] = [[{ f: `clash/sword_clash.${n}.ogg`, len: 0.4, fade: 0.2 }], 0.75]);
R.block_wood_1 = [[{ f: C('wooden_02'), speed: 1.1 }, { f: IM(2), lp: 2000, gain: 0.4 }], 0.75];
R.block_wood_2 = [[{ f: C('wooden_03'), speed: 1.05 }, { f: IM(6), lp: 2000, gain: 0.4 }], 0.75];
R.block_body_1 = [[{ f: IM(2), lp: 1300, len: 0.15 }, { f: K('cloth2'), len: 0.12, gain: 0.4 }], 0.6];
R.block_body_2 = [[{ f: IM(3), lp: 1300, len: 0.15 }, { f: K('cloth2'), len: 0.12, gain: 0.4 }], 0.6];
R.counter = [[{ f: 'clash/sword_clash.1.ogg', len: 0.5, fade: 0.25 }, { f: SW(1), gain: 0.5, delay: 0.05, hp: 500 }], 0.85];

// --- misc fight
R.throw_1 = [[{ f: SW(2), speed: 1.45, hp: 1200 }], 0.4];
R.throw_2 = [[{ f: SW(10), speed: 1.35, hp: 1200 }], 0.4];
R.land_1 = [[{ f: K('footstep08'), speed: 0.6, lp: 1200 }, { f: C('slam_04'), speed: 0.8, lp: 1500, gain: 0.7 }], 0.7];
R.land_2 = [[{ f: K('footstep01'), speed: 0.6, lp: 1200 }, { f: C('slam_04'), speed: 0.75, lp: 1500, gain: 0.7 }], 0.7];
R.wall = [[{ f: C('slam_03'), lp: 2000 }, { f: IM(10), speed: 0.8, lp: 2500, gain: 0.7 }], 0.9];
R.ko = [[
  { f: C('slam_03'), speed: 0.8, lp: 1500 },
  { f: C('explosion'), speed: 0.55, lp: 700, gain: 0.9 },
  { f: C('gong_02'), speed: 0.75, gain: 0.35, delay: 0.06, fade: 0.4 },
], 0.95];
R.boom = [[{ f: C('explosion') }, { f: C('slam_06'), speed: 0.8, gain: 0.6 }], 0.95];
R.gong = [[{ f: C('gong_01'), speed: 0.7, fade: 0.5 }], 0.8];

// --- voices. Male: HaelDB grunts/yells (CC0).
['3grunt1', '3grunt4', '3grunt5', '1yell1', '1yell9', '3yell3', '1yell16'].forEach((n, i) =>
  R[`hurt_m_${i + 1}`] = [[{ f: VM(n), len: 0.42, fade: 0.12 }], 0.75]);
['1yell2', '3yell4', '1yell7', 'yell12'].forEach((n, i) =>
  R[`hurtbig_m_${i + 1}`] = [[{ f: VM(n), len: 0.65, fade: 0.2 }], 0.85]);
['3yell1', 'yell11'].forEach((n, i) => R[`ko_m_${i + 1}`] = [[{ f: VM(n), len: 1.2, fade: 0.4 }], 0.85]);
['yell2', 'yell5', '3yell15', '1yell4'].forEach((n, i) =>
  R[`kiai_m_${i + 1}`] = [[{ f: VM(n), len: 0.55, fade: 0.18 }], 0.7]);
// Female: Marti Topmade's free combat voice sample (credit required, raw files
// not redistributable -> gitignored; get it from topmademarti.itch.io).
const VF = (n) => `voice_f/topmademarti/combat_${n}_.wav`;
['pain_light_02', 'grunt_01', 'grunt_03'].forEach((n, i) =>
  R[`hurt_f_${i + 1}`] = [[{ f: VF(n), len: 0.4, fade: 0.12 }], 0.7]);
R.hurt_f_4 = [[{ f: VF('pain_light_02'), len: 0.4, speed: 1.06, fade: 0.12 }], 0.7];
['pain_01', 'pain_02'].forEach((n, i) => R[`hurtbig_f_${i + 1}`] = [[{ f: VF(n), len: 0.7, fade: 0.2 }], 0.8]);
R.ko_f_1 = [[{ f: VF('pain_01'), speed: 0.9, fade: 0.3 }], 0.8];
R.ko_f_2 = [[{ f: VF('pain_02'), speed: 0.88, fade: 0.3 }], 0.8];
['attack_02', 'swing_01', 'swing_04'].forEach((n, i) =>
  R[`kiai_f_${i + 1}`] = [[{ f: VF(n), len: 0.6, fade: 0.18 }], 0.75]);

// ------------------------------------------------------------- main
fs.mkdirSync(OUT, { recursive: true });
let total = 0;
for (const [name, [layers, pk]] of Object.entries(R)) {
  const x = await build(layers, pk);
  writeWav(path.join(OUT, name + '.wav'), x);
  total += x.length * 2;
  console.log(name.padEnd(16), (x.length / SR).toFixed(2) + 's');
}
console.log(`${Object.keys(R).length} sounds, ${(total / 1024).toFixed(0)} KB`);
