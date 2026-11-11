# Icon võ công (ChatGPT) — 5 tấm, mỗi tấm 6 icon

1. Mở chat ChatGPT mới, dán **PHẦN CHUNG** rồi dán prompt của phái.
2. Tải ảnh về, đổi tên đúng cột "Tên file", thả vào thư mục này (`assets_src/skills/`).
3. Thứ tự icon trong tấm phải đúng thứ tự chiêu 1→6 (hàng trên trái→phải, rồi hàng dưới).
   Nếu ChatGPT vẽ sai thứ tự hay thiếu icon, bảo nó vẽ lại.

## PHẦN CHUNG
```
A sheet of 6 skill icons for a Vietnamese wuxia mobile fighting game, painted ink-wash style, rich color. Layout: 3 icons in the top row, 3 icons in the bottom row, in reading order, with wide empty gaps between icons. Each icon is a round emblem filling a circle, no frame, no ring, no text, no human faces. Transparent background (PNG). Canvas 1536x1024.
```

## PROMPT TỪNG PHÁI
| Tên file | Prompt |
|---|---|
| `thieu_lam.png` | `Golden-orange Shaolin monk theme. 1) A fist striking with three golden afterimage punches. 2) A glowing golden bell dome shield. 3) A wooden staff spinning in a whirlwind circle. 4) A roaring golden lion head with sound shockwaves. 5) A staff thrusting upward with a tiger spirit leaping up. 6) A blazing golden Buddha silhouette in meditation with a radiant halo, more ornate (ultimate).` |
| `vo_dang.png` | `Sky blue and white Taoist theme. 1) A sword tracing circular taiji arcs. 2) A yin-yang symbol deflecting an incoming strike. 3) A long blue crescent of sword energy flying forward. 4) A sword plunging down through clouds. 5) A calm meditation mat with swirling blue qi mist. 6) A huge taiji diagram with six flying swords radiating outward, more ornate (ultimate).` |
| `nga_mi.png` | `Pink and white Emei theme with lotus motifs. 1) Twin swords flowing like water ribbons. 2) Soft rays of Buddha light over a small pink lotus, healing glow. 3) A sword thrust piercing through snowflakes and clouds. 4) An open palm with a soft golden cloud spiral. 5) Pink flower petals scattering like sharp darts. 6) A giant blooming radiant pink lotus, more ornate (ultimate).` |
| `cai_bang.png` | `Warm brown and gold Beggar Sect theme. 1) A powerful open palm strike with a golden shockwave. 2) A tilted wine gourd with a swaying fist and motion blur. 3) A golden dragon head bursting out of a palm. 4) A green bamboo staff parrying with a counterstrike spark. 5) A wine gourd pouring with a fiery red aura. 6) A golden dragon soaring upward into the sky, more ornate (ultimate).` |
| `duong_mon.png` | `Dark green and purple poison Tang Clan theme. 1) Three flying knives in a row. 2) A single green glowing poison needle dripping venom. 3) A dark shadow silhouette dashing with afterimages. 4) A black iron bomb with a sparkling fuse and fiery thunder. 5) A storm of dozens of needles bursting from a small case. 6) A net of poison mist with countless blades raining down, more ornate (ultimate).` |

Sau đó: `godot --headless --path . --script res://tools/icon_cut.gd` cắt thành `assets/ui/skills/<phai>_<0..5>.png`.
