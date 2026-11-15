# Icon nguyên liệu rèn + icon Phó Bản (ChatGPT) — 1 tấm

1. Mở chat ChatGPT mới, dán prompt bên dưới.
2. Tải ảnh về, đặt tên `nguyen_lieu.png`, thả vào thư mục này (`assets_src/items/`).
3. Thứ tự icon phải đúng như prompt (hàng trên trái→phải, rồi hàng dưới). Sai thứ tự hay thiếu icon thì bảo vẽ lại.
4. Chạy `godot --headless --path . --script res://tools/icon_cut.gd -- nguyen_lieu`
   → `assets/ui/mats/iron|star|wash|charm.png` và `assets/ui/menu/dungeon.png`.
   Chưa có icon thì game hiện viên đá màu có chữ (T, ★, L, P).

## Prompt — `nguyen_lieu.png` (5 icon: 3 trên, 2 dưới, canvas 1536x1024)
```
A sheet of item icons for a Vietnamese wuxia mobile fighting game, painted ink-wash style with rich color and gold accents, consistent style across all icons. Each icon is a single object centered, no frame, no ring, no text, no letters, no human faces. Wide empty gaps between icons. Transparent background (PNG).
5 icons, 3 in the top row and 2 in the bottom row, in reading order:
1) Huyen Thiet: a heavy chunk of dark blue-black meteoric iron ore with silver veins, cool steel blue glow.
2) Thien Tinh Thach: a faceted golden star crystal shard glowing like a fallen star, warm gold light.
3) Tay Luyen Thach: a smooth jade-green river stone with flowing water-like swirl patterns, soft green mist.
4) Ho Phu: a red paper talisman charm with gold brush patterns (abstract, no readable characters) tied with a red string and a small jade bead.
5) Dungeon: a dark mountain cave entrance with a stone gate, blue mist and glowing crystals inside, round emblem filling a circle.
```
