# Icon trang bị (ChatGPT): Y phục, Đầu quan, Hài, Ngọc bội — 4 tấm, mỗi tấm 7 bậc

Dùng chung cho mọi phái. Mỗi tấm vẽ **cùng một món qua 7 bậc**:
1 Mộc → 2 Đồng → 3 Thiết → 4 Cương → 5 Ngân → 6 Huyền → 7 Thiên.
Độ hiếm game tự tô màu khung, không cần vẽ.

1. Mở chat ChatGPT mới cho mỗi tấm, dán **PHẦN CHUNG** rồi dán prompt của món đó.
2. Tải ảnh, đặt đúng tên ở cột "Tên file", thả vào thư mục này (`assets_src/items/`).
3. Thứ tự: hàng trên 4 món (bậc 1→4), hàng dưới 3 món (bậc 5→7). Thiếu món, sai thứ tự,
   có chữ/số hoặc có người mặc thì bảo vẽ lại.
4. Báo mình, hoặc tự chạy:
   `godot --headless --path . --script res://tools/icon_cut.gd -- armor hat boots jade`
   → `assets/ui/items/<armor|hat|boots|jade>_<1..7>.png`.

## PHẦN CHUNG
```
A sheet of 7 equipment icons for a Vietnamese wuxia mobile fighting game, painted ink-wash style with rich color and soft rim light. It shows THE SAME item upgraded through 7 tiers, getting more refined and precious from left to right:
1) plain cloth/wood, 2) bronze, 3) dark iron, 4) tempered blue steel, 5) engraved silver, 6) black jade with a faint purple glow, 7) heavenly gold and white jade with a radiant aura (most ornate).
Layout: 4 icons in the top row, 3 icons in the bottom row, in reading order, with wide empty gaps between icons. Each item shown whole, front view, centered in its own space, same size. No frame, no circle, no background shapes, no text, no numbers, no people, no body wearing it. Transparent background (PNG). Canvas 1536x1024.
```

## PROMPT TỪNG MÓN
| Tên file | Món | Prompt |
|---|---|---|
| `armor.png` | Y Phục (Bào) | `The item: a martial artist's robe with a wide sash, laid flat like on display. Low tiers are plain hemp cloth; then bronze-studded leather, iron lamellar plates over the robe, blue steel scale armor, silver-engraved armor with cloud patterns, black jade armor with purple trims, and finally a white-and-gold heavenly armor robe with flowing ribbons.` |
| `hat.png` | Đầu Quan | `The item: a martial artist's headpiece. Low tiers are a simple cloth headband; then a bronze hair crown, an iron helmet, a blue steel helmet with a plume, a silver crown with phoenix engravings, a black jade crown, and finally a radiant gold-and-white-jade heavenly crown.` |
| `boots.png` | Hài | `The item: a pair of martial arts boots, side view. Low tiers are straw sandals; then cloth shoes, leather boots with iron toe caps, blue steel greaves, silver-engraved boots with wing motifs, black jade boots, and finally gold-and-white-jade heavenly boots with a cloud aura at the soles.` |
| `jade.png` | Ngọc Bội | `The item: a hanging jade pendant with a knotted silk cord and tassel. Low tiers are a plain carved wooden token; then bronze, dark stone, a blue crystal disc, a silver-framed jade with dragon carving, a black jade glowing purple, and finally a radiant white-and-gold jade with a phoenix carving.` |
