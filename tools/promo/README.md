# Promo video (Nam Minh voice)

46 s narrated ad: gameplay clips recorded with Godot's Movie Maker, Vietnamese
voice-over (Edge neural TTS vi-VN-NamMinhNeural +5%), subtitles, the fight
theme ducked under the voice, and a logo end card. Same idea as Kiếm Hiệp's
tool/promo/v170.

1. `npm install` here (node-edge-tts@1.2.11). ffmpeg is not on this machine:
   unzip a BtbN build (ffmpeg-n8.1-latest-win64-gpl-8.1) and point `FF` at its bin.
2. `FF=... bash capture.sh [a b c d k]`: records clips/<id>.mkv at 1920x1080,
   30 fps, game sound only (`--promo --nomusic`). Movie Maker ignores
   `--resolution`, so the script writes a temporary override.cfg.
   Fights are not frame-identical between runs: after a recapture, check where
   the action / the ink finisher falls and update `"at"` in script.json.
3. Voice: `node say.js vi-VN-NamMinhNeural +5% +0Hz voice/<id>.raw.mp3 "<line>"`, then
   `ffmpeg -i raw.mp3 -af "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5:LRA=11" -ar 44100 -ac 2 voice/<id>.wav`.
4. Stills in stills/ come from store/phone (+ the map screen).
5. `FF=... node build.js` writes out/vo-lam-promo-16x9.mp4 and -9x16.mp4
   (copied to store/video).

## Female voice version (_nu)

Livelier read by Hoài My: `script_f.json` (ids f1–f9), voice made with
`node say.js vi-VN-HoaiMyNeural +14% +6Hz voice/fN.raw.mp3 "<line>"` and the
same ffmpeg clean-up (loudnorm I=-15). `TAG=_nu FF=... node build.js` uses
script_f.json, shorter gaps (0.55 s) and louder music, and writes
out/vo-lam-promo_nu-16x9.mp4 / -9x16.mp4.

## 15 s TikTok cut (_15)

`script_15.json` (t1–t5, Hoài My +18%), optional per-line `"hold"` seconds
keeps a scene up after the line. `TAG=_15 FF=... node build.js` →
out/vo-lam-promo_15-9x16.mp4 (+ a 16x9 for Shorts-style reuse).
