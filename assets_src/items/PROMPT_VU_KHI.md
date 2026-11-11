# Icon vũ khí (ChatGPT): 5 tấm, mỗi tấm 7 bậc

Mỗi phái một loại vũ khí; mỗi tấm vẽ **cùng một món qua 7 bậc nâng cấp**:
1 Mộc → 2 Đồng → 3 Thiết → 4 Cương → 5 Ngân → 6 Huyền → 7 Thiên.
Độ hiếm (Phàm/Tinh/Bảo/Thần/Truyền Thuyết) game tự tô màu khung, không cần vẽ.

1. Mở chat ChatGPT mới, dán **PHẦN CHUNG** rồi dán prompt của loại vũ khí.
2. Tải ảnh, đặt đúng tên ở cột "Tên file", thả vào thư mục này (`assets_src/items/`).
3. Thứ tự: hàng trên 4 món (bậc 1→4, trái sang phải), hàng dưới 3 món (bậc 5→7).
   Thiếu món, sai thứ tự hoặc có chữ/số trên hình thì bảo ChatGPT vẽ lại.

## PHẦN CHUNG
```
A sheet of 7 weapon icons for a Vietnamese wuxia mobile fighting game, painted ink-wash style with rich color and soft rim light. It shows THE SAME weapon upgraded through 7 tiers, getting more refined and precious from left to right:
1) plain wood, 2) bronze, 3) dark iron, 4) tempered blue steel, 5) engraved silver, 6) black jade with a faint purple glow, 7) heavenly gold and white jade with a radiant aura (most ornate).
Layout: 4 icons in the top row, 3 icons in the bottom row, in reading order, with wide empty gaps between icons. Each weapon shown whole, at the same diagonal angle (pointing up-right), centered in its own space. No frame, no circle, no background shapes, no text, no numbers, no hands or people. Transparent background (PNG). Canvas 1536x1024.
```

## PROMPT TỪNG LOẠI
| Tên file | Phái | Prompt |
|---|---|---|
| `weapon_staff.png` | Thiếu Lâm (Côn) | `The weapon: a long Shaolin fighting staff with metal end caps. Higher tiers add carved Buddhist patterns, prayer bead ornaments tied near one end and golden end caps.` |
| `weapon_sword.png` | Võ Đang (Kiếm) | `The weapon: a straight double-edged Chinese jian sword with a cross guard and a short tassel on the pommel. Higher tiers add cloud patterns on the blade, a taiji emblem on the guard and a longer silk tassel.` |
| `weapon_dual.png` | Nga Mi (Song Kiếm) | `The weapon: a pair of slender short twin swords crossed in an X. Higher tiers add lotus engravings, pink silk ribbons on the hilts and a soft pink glow.` |
| `weapon_palm.png` | Cái Bang (Hộ Thủ) | `The weapon: a pair of martial arts forearm guards with knuckle plates, wrapped in cloth. Higher tiers turn the cloth into leather, then metal plates with a dragon relief and glowing palm runes.` |
| `weapon_dagger.png` | Đường Môn (Ám Khí) | `The weapon: a short curved dagger with three small throwing knives fanned beside it. Higher tiers add green poison runes on the blades, a dark leather grip and a faint green venom mist.` |

Sau đó: `godot --headless --path . --script res://tools/icon_cut.gd -- weapon_staff weapon_sword weapon_dual weapon_palm weapon_dagger`
→ `assets/ui/items/weapon_<loại>_<1..7>.png`, hiện ngay trong Trang Bị và Tiệm Binh Khí.

## Sau này (cùng cách làm, mỗi tấm 7 bậc)
Y phục (`armor.png`), đầu quan (`hat.png`), hài (`boots.png`), ngọc bội (`jade.png`): dùng chung cho mọi phái.
