// Assembles the narrated promo: scenes timed to the Nam Minh voice lines,
// the game's own fight sounds (recorded with each clip), the fight theme
// ducked under the voice, Vietnamese subtitles and a logo end card.
// Writes out/vo-lam-promo${TAG}-16x9.mp4 and out/vo-lam-promo${TAG}-9x16.mp4.
// usage: FF=<ffmpeg bin dir> node build.js
const fs = require('fs');
const { execFileSync } = require('child_process');

const FFD = process.env.FF;
if (!FFD) throw new Error('set FF to the ffmpeg bin dir');
const FF = `${FFD}/ffmpeg.exe`;
const FP = `${FFD}/ffprobe.exe`;
const P = '../..';
const MUSIC = `${P}/assets/audio/music_fight.wav`;
const LOGO = `${P}/assets/art/logo.png`;
const CLICK = `${P}/assets/audio/click.wav`;
const GONG = `${P}/assets/audio/gong.wav`;
const FONT_B = 'fonts/BeVietnamPro-Bold.ttf';

const ff = (args) => execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', ...args], { stdio: 'inherit' });
const dur = (f) => parseFloat(execFileSync(FP, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).toString());
const ENC = ['-r', '30', '-c:v', 'libx264', '-crf', '17', '-preset', 'medium', '-pix_fmt', 'yuv420p'];
const SIL = (len) => ['-f', 'lavfi', '-t', len.toFixed(3), '-i', 'anullsrc=r=44100:cl=stereo'];

// TAG=_nu: script_f.json (HoaiMy voice), snappier gaps, louder music.
const TAG = process.env.TAG || '';
// TAG=_15: script_15.json, a 15 s TikTok cut (same voice, tighter gaps).
const script = JSON.parse(fs.readFileSync({ _nu: 'script_f.json', _15: 'script_15.json', _wb: 'script_wb.json' }[TAG] || 'script.json', 'utf8'));
for (const d of ['seg', 'out', 'txt']) fs.mkdirSync(d, { recursive: true });
fs.writeFileSync('txt/tagline.txt', 'Game đối kháng võ lâm 3D');
fs.writeFileSync('txt/cta.txt', 'TẢI MIỄN PHÍ TRÊN GOOGLE PLAY');

const GAP = { _nu: 0.55, _15: 0.35, _wb: 0.45 }[TAG] ?? 0.9;
// TAG=_wb: 1.2.1 promo (Boss Thế Giới + new features), end card over the boss clip
const END_CLIP = TAG === "_wb" ? "w" : "a";
const MVOL = TAG ? 0.62 : 0.5;
let t = 0;
const segs = [];    // video+game-audio segments (all with an audio track)
const extra = [];   // {at, file, vol}
const subs = [];
const voices = [];
let endAt = 0;

script.forEach((line, n) => {
  const vfile = `voice/${line.id}.wav`;
  const lead = n === 0 ? 0.3 : 0;
  const len = dur(vfile) + GAP + lead + (line.hold ?? 0);   // hold: keep the scene on screen longer
  voices.push({ at: t + lead, file: vfile });
  const sub = `txt/${line.id}.txt`;
  fs.writeFileSync(sub, line.sub);
  if (line.scene !== 'end') subs.push({ from: t + lead, to: t + len - 0.15, file: sub });
  const out = `seg/${line.id}.mkv`;
  const [kind, arg] = line.scene.split(':');
  if (kind === 'clip') {
    ff(['-ss', String(line.at ?? 2), '-t', len.toFixed(3), '-i', `clips/${arg}.mkv`,
      '-af', 'aresample=44100,aformat=channel_layouts=stereo', ...ENC, '-c:a', 'pcm_s16le', out]);
  } else if (kind === 'still' || kind === 'stills') {
    const names = arg.split(',');
    const each = len / names.length;
    const parts = names.map((name, i) => {
      const p = `seg/${line.id}_${i}.mkv`;
      const frames = Math.round(each * 30);
      ff(['-loop', '1', '-framerate', '30', '-t', each.toFixed(3), '-i', `stills/${name}.png`, ...SIL(each), '-vf',
        `scale=1920:1080,zoompan=z='1+0.05*on/${frames}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=30`,
        '-shortest', ...ENC, '-c:a', 'pcm_s16le', p]);
      extra.push({ at: t + i * each, file: CLICK, vol: 0.6 });
      return p;
    });
    ff([...parts.flatMap((p) => ['-i', p]), '-filter_complex',
      `${parts.map((_, i) => `[${i}:v][${i}:a]`).join('')}concat=n=${parts.length}:v=1:a=1[v][a]`,
      '-map', '[v]', '-map', '[a]', ...ENC, '-c:a', 'pcm_s16le', out]);
  } else if (kind === 'end') {
    const L = len + 1.5;
    ff(['-ss', '3.0', '-i', `clips/${END_CLIP}.mkv`, '-frames:v', '1', 'seg/bg.png']);
    ff(['-loop', '1', '-framerate', '30', '-t', L.toFixed(3), '-i', 'seg/bg.png', '-loop', '1', '-t', L.toFixed(3), '-i', LOGO, ...SIL(L),
      '-filter_complex',
      '[0]scale=1920:1080,boxblur=18:3,eq=brightness=-0.28[b];[1]scale=900:-1[l];[b][l]overlay=(W-w)/2:40[bl];' +
      `[bl]drawtext=fontfile=${FONT_B}:textfile=txt/tagline.txt:fontsize=54:fontcolor=0xF3E6C8:borderw=3:bordercolor=0x2A1810:x=(w-text_w)/2:y=660,` +
      `drawtext=fontfile=${FONT_B}:textfile=txt/cta.txt:fontsize=58:fontcolor=white:box=1:boxcolor=0xA3271F:boxborderw=28:x=(w-text_w)/2:y=820,` +
      'fade=t=in:st=0:d=0.35[v]', '-map', '[v]', '-map', '2:a', '-shortest', ...ENC, '-c:a', 'pcm_s16le', out]);
    ff(['-i', 'seg/bg.png', '-i', LOGO, '-filter_complex',
      '[0]scale=-2:1920,crop=1080:1920,boxblur=22:3,eq=brightness=-0.3[b];[1]scale=980:-1[l];[b][l]overlay=(W-w)/2:420[bl];' +
      `[bl]drawtext=fontfile=${FONT_B}:textfile=txt/tagline.txt:fontsize=56:fontcolor=0xF3E6C8:borderw=3:bordercolor=0x2A1810:x=(w-text_w)/2:y=1110,` +
      `drawtext=fontfile=${FONT_B}:textfile=txt/cta.txt:fontsize=50:fontcolor=white:box=1:boxcolor=0xA3271F:boxborderw=26:x=(w-text_w)/2:y=1300`,
      '-frames:v', '1', 'seg/end_v.png']);
    extra.push({ at: t, file: GONG, vol: 0.9 });
    segs.push(out);
    endAt = t;
    t += L;
    return;
  }
  segs.push(out);
  t += len;
});
const TOTAL = t;
console.log('total', TOTAL.toFixed(2), 's');

// Video + game sound: concat all segments.
ff([...segs.flatMap((s) => ['-i', s]), '-filter_complex',
  `${segs.map((_, i) => `[${i}:v][${i}:a]`).join('')}concat=n=${segs.length}:v=1:a=1[v][a]`,
  '-map', '[v]', '-map', '[a]', ...ENC, '-c:a', 'pcm_s16le', 'seg/master.mkv']);

const mix = (items, outFile) => {
  const chains = items.map((s, i) => `[${i}]aresample=44100,aformat=channel_layouts=stereo,volume=${s.vol ?? 1},adelay=${Math.round(s.at * 1000)}|${Math.round(s.at * 1000)}[a${i}]`);
  ff([...items.flatMap((s) => ['-i', s.file]), '-filter_complex',
    `${chains.join(';')};${items.map((_, i) => `[a${i}]`).join('')}amix=inputs=${items.length}:normalize=0:duration=longest,apad=whole_dur=${TOTAL.toFixed(3)}[o]`,
    '-map', '[o]', '-t', TOTAL.toFixed(3), '-c:a', 'pcm_s16le', outFile]);
};
mix(voices, 'seg/voice.wav');
mix(extra, 'seg/extra.wav');
ff(['-stream_loop', '-1', '-i', MUSIC, '-i', 'seg/voice.wav', '-i', 'seg/master.mkv', '-i', 'seg/extra.wav', '-filter_complex',
  `[0]atrim=0:${TOTAL.toFixed(3)},aresample=44100,aformat=channel_layouts=stereo,volume=${MVOL},afade=t=in:d=0.4,afade=t=out:st=${(TOTAL - 2).toFixed(2)}:d=2[m];` +
  '[1]asplit=3[v][vk][vk2];' +
  '[m][vk]sidechaincompress=threshold=0.03:ratio=8:attack=20:release=350[md];' +
  '[2:a]volume=0.75[g];[g][vk2]sidechaincompress=threshold=0.03:ratio=3:attack=20:release=300[gd];' +
  '[3]volume=0.8[fx];' +
  '[md][v][gd][fx]amix=inputs=4:normalize=0,alimiter=limit=0.95[o]',
  '-map', '[o]', '-t', TOTAL.toFixed(3), '-c:a', 'pcm_s16le', 'seg/mix.wav']);

const subFilter = (fs_, y) => subs.map((s) =>
  `drawtext=fontfile=${FONT_B}:textfile=${s.file}:fontsize=${fs_}:fontcolor=white:line_spacing=10:` +
  `borderw=6:bordercolor=0x1A0E0A:box=1:boxcolor=0x1A0E0A@0.5:boxborderw=18:shadowcolor=black@0.55:shadowx=3:shadowy=3:text_align=C:x=(w-text_w)/2:y=${y}:` +
  `enable='between(t,${s.from.toFixed(2)},${s.to.toFixed(2)})':alpha='if(lt(t-${s.from.toFixed(2)},0.2),(t-${s.from.toFixed(2)})/0.2,1)'`).join(',');
const OUTA = ['-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart'];

ff(['-i', 'seg/master.mkv', '-i', 'seg/mix.wav', '-filter_complex', `[0:v]${subFilter(60, 'h-text_h-60')}[v]`,
  '-map', '[v]', '-map', '1:a', '-r', '30', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
  ...OUTA, `out/vo-lam-promo${TAG}-16x9.mp4`]);

// 9:16: blurred fill, the game in the middle band, logo on top, subtitles and
// CTA below; the end card is shown full-height instead.
const pre = endAt.toFixed(2);
ff(['-i', 'seg/master.mkv', '-i', 'seg/mix.wav', '-loop', '1', '-i', LOGO, '-loop', '1', '-i', 'seg/end_v.png', '-filter_complex',
  '[0:v]split=2[x][y];' +
  '[x]scale=-2:1920,crop=1080:1920,boxblur=26:4,eq=brightness=-0.25[bg];[y]scale=1080:-2[fg];[bg][fg]overlay=0:(H-h)/2[base];' +
  '[2]scale=860:-1[lg];[base][lg]overlay=(W-w)/2:150:shortest=1:enable=\'lt(t,' + pre + ')\'[wl];' +
  `[wl]${subFilter(52, 1330)},` +
  `drawtext=fontfile=${FONT_B}:textfile=txt/cta.txt:fontsize=46:fontcolor=white:box=1:boxcolor=0xA3271F:boxborderw=22:x=(w-text_w)/2:y=1640:enable='lt(t,${pre})'[pre];` +
  '[pre][3]overlay=0:0:shortest=1:enable=\'gte(t,' + pre + ')\'[v]',
  '-map', '[v]', '-map', '1:a', '-r', '30', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
  ...OUTA, `out/vo-lam-promo${TAG}-9x16.mp4`]);
console.log('done');
