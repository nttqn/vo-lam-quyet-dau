import fs from 'fs';
import { MPEGDecoder } from 'mpg123-decoder';
import { OggVorbisDecoder } from '@wasm-audio-decoders/ogg-vorbis';

function toMono(ch) {
  const n = ch[0].length, x = new Float32Array(n);
  for (const c of ch) for (let i = 0; i < n; i++) x[i] += c[i] / ch.length;
  return x;
}

/** PCM WAV (8/16/24/32-bit int, 32-bit float), mixed down to mono. */
function readWav(b) {
  let p = 12, fmt = null;
  while (p + 8 <= b.length) {
    const id = b.toString('ascii', p, p + 4), size = b.readUInt32LE(p + 4), body = p + 8;
    if (id === 'fmt ') {
      fmt = { tag: b.readUInt16LE(body), ch: b.readUInt16LE(body + 2), sr: b.readUInt32LE(body + 4), bits: b.readUInt16LE(body + 14) };
      if (fmt.tag === 0xfffe) fmt.tag = b.readUInt16LE(body + 24); // WAVE_FORMAT_EXTENSIBLE sub-format
    } else if (id === 'data' && fmt) {
      const bps = fmt.bits / 8, n = Math.floor(Math.min(size, b.length - body) / (bps * fmt.ch)), x = new Float32Array(n);
      for (let i = 0; i < n; i++) {
        let s = 0;
        for (let c = 0; c < fmt.ch; c++) {
          const o = body + (i * fmt.ch + c) * bps;
          let v;
          if (fmt.tag === 3) v = b.readFloatLE(o);
          else if (fmt.bits === 8) v = (b[o] - 128) / 128;
          else if (fmt.bits === 16) v = b.readInt16LE(o) / 32768;
          else if (fmt.bits === 24) v = b.readIntLE(o, 3) / 8388608;
          else v = b.readInt32LE(o) / 2147483648;
          s += v;
        }
        x[i] = s / fmt.ch;
      }
      return { x, sr: fmt.sr };
    }
    p = body + size + (size & 1);
  }
  throw new Error('bad wav');
}

/** Returns {x: Float32Array mono, sr}. A fresh decoder per file (a shared Vorbis decoder carries state over). */
export async function load(p) {
  const buf = fs.readFileSync(p);
  if (/\.wav$/i.test(p)) return readWav(buf);
  const mp3 = /\.mp3$/i.test(p);
  const d = mp3 ? new MPEGDecoder() : new OggVorbisDecoder();
  await d.ready;
  const r = mp3 ? d.decode(new Uint8Array(buf)) : await d.decodeFile(new Uint8Array(buf));
  d.free();
  return { x: toMono(r.channelData), sr: r.sampleRate };
}
