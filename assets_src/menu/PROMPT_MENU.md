# Icon menu sảnh chính (ChatGPT) — 2 tấm

1. Mở chat ChatGPT mới, dán **PHẦN CHUNG** của tấm rồi dán prompt.
2. Tải ảnh về, đặt đúng tên file, thả vào thư mục này (`assets_src/menu/`).
3. Thứ tự icon phải đúng như prompt (hàng trên trái→phải, rồi hàng dưới). Sai thứ tự hay thiếu icon thì bảo vẽ lại.
4. Chạy `godot --headless --path . --script res://tools/icon_cut.gd -- menu_1 menu_2` để cắt ra `assets/ui/menu/<tên>.png`.
   Chưa có icon nào thì game hiện huy hiệu chữ cái thay thế.

## PHẦN CHUNG
```
A sheet of game menu icons for a Vietnamese wuxia mobile fighting game, painted ink-wash style with rich color and gold accents, consistent style across all icons. Each icon is a round emblem filling a circle, no frame, no ring, no text, no letters, no human faces. Wide empty gaps between icons. Transparent background (PNG).
```

## Tấm 1 — `menu_1.png` (6 icon: 3 trên, 3 dưới, canvas 1536x1024)
```
6 icons, 3 in the top row and 3 in the bottom row, in reading order:
1) Journey: a winding mountain road with a lone sword stuck in the ground and distant pagoda, warm sunset gold.
2) Duel: two crossed swords clashing with a red spark, crimson.
3) Trial tower: a tall seven-storey pagoda tower glowing at the top, purple night sky.
4) Arena: a round stone fighting platform with red banners and flames, orange.
5) Training: a wooden training dummy with a bamboo staff, teal-green.
6) Ranking: a golden trophy cup with a laurel and a scroll, gold.
```

## Tấm 2 — `menu_2.png` (8 icon: 4 trên, 4 dưới, canvas 1536x1024)
```
8 icons, 4 in the top row and 4 in the bottom row, in reading order:
1) Character: a martial artist's headband and a fist over an ink circle, red.
2) Martial skills: an open ancient martial arts manual scroll with glowing qi, blue.
3) Equipment: a sword and a lamellar armor chestplate, steel grey.
4) Weapon shop: a hanging shop banner with a sword rack and gold coins, amber.
5) Outfit: a folded silk robe with a jade belt clasp, magenta.
6) Daily quests: a sealed quest scroll with a red wax seal and a brush, green.
7) Settings: a bronze gear-shaped ancient coin, dark grey.
8) Leave: an open wooden gate door with mist outside, dark red.
```
