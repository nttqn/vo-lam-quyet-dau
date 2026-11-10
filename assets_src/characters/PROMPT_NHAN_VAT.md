# Prompt tạo ảnh nhân vật (ChatGPT) → Meshy Pro

## Cách dùng
1. Mở cuộc chat ChatGPT mới, **đính kèm ảnh Thiếu Lâm đã làm** (để giữ đúng nét vẽ).
2. Dán **PHẦN CHUNG** + **PHẦN RIÊNG** của phái.
3. Ảnh ra là tấm 3 góc → cắt thành 3 ảnh riêng: trước / bên / sau.
4. Meshy: Image to 3D → bật **Nhiều góc nhìn** → đưa 3 ảnh vào 3 ô → Meshy 7.1, bật Kết cấu, Tư thế = **T-Pose** → Tạo ra.
5. Hoạt hình → Áp rig (chiều cao ~1.7 m) → Tải xuống: **fbx**, Mẫu bộ xương **Mixamo**, **Nhân vật đã được rigging** bật, **Hoạt hình** tắt, **Với Da**.
6. Lưu `assets_src/characters/<Phai>.fbx`: `ThieuLam.fbx`, `VoDang.fbx`, `NgaMi.fbx`, `CaiBang.fbx`, `DuongMon.fbx`.

## PHẦN CHUNG (dán trước mỗi phái)
```
Use the attached image as the exact art style reference: same stylized 3D game character look, same proportions, same face style, same painted textures and lighting.

Character turnaround sheet of ONE character: front view, side view, back view, evenly spaced, same scale, feet on the same ground line. Full body, strict T-pose with arms straight out horizontally, palms down, fingers together, legs straight and slightly apart. Neutral expression, mouth closed.

Ancient Chinese wuxia martial artist. Outfit must be fitted for fighting: tunic no longer than the knee, side slits, fitted sleeves ending at the wrist, trousers tucked into leg wraps or boots, cloth belt. NO weapon, NO cape, NO long flowing sleeves, NO floor-length robe, NO loose ribbons, NO hat brim wider than the head, nothing floating away from the body. Hair kept close to the head (bun, ponytail or short), no strands flying out.

Plain pure white background, flat even studio lighting, no cast shadows, no text, no labels.
```

## PHẦN RIÊNG
**Võ Đang** (nam)
```
Wudang Taoist swordsman, young man, calm and dignified. White tunic with pale blue-grey trim and a subtle yin-yang emblem on the chest, light grey trousers, white cloth leg wraps, black cloth shoes. Long black hair tied in a neat topknot with a simple wooden hairpin.
```

**Nga Mi** (nữ)
```
Emei sect swordswoman, young woman, graceful but athletic. White tunic with soft pink and rose trim, lotus pattern embroidered on the hem, pale pink trousers, white leg wraps, light cloth shoes. Long black hair in a high ponytail tied with a pink ribbon kept short and close to the head.
```

**Cái Bang** (nam)
```
Beggar Sect fighter, sturdy middle-aged man with short stubble beard, cheerful rough face. Faded brown and dull green patched tunic with visible stitched patches, rope belt with a small wine gourd tied tight at the hip, rolled patched trousers, straw sandals with leg wraps. Messy short hair tied back with a cloth strip.
```

**Đường Môn** (nam)
```
Tang Clan hidden-weapon assassin, lean young man, sharp eyes. Tight dark green and black tunic, leather bracers on the forearms, black belt with small flat pouches, dark trousers, black boots. Short black hair tied back, a dark cloth mask covering the lower half of the face.
```

**Thiếu Lâm** (đã có — làm lại khi cần)
```
Shaolin warrior monk, young man, bald with incense burn dots on the forehead. Saffron orange tunic with cream trim, dark brown sash, wooden prayer bead necklace worn tight around the neck, brown wide trousers with white leg wraps, brown cloth shoes.
```

## Bộ đồ cao cấp (sau này)
Đính kèm ảnh nhân vật cơ bản của phái đó + PHẦN CHUNG, rồi:
```
Same character, same face, same hairstyle and body. New premium outfit: <mô tả bộ đồ>. Keep all the outfit rules above.
```
Mỗi phái một bộ riêng (thay `<mô tả bộ đồ>`):

**Thiếu Lâm — Kim Cang**
```
golden yellow tunic with deep red trim, embroidered golden dragon on the back, red sash with short gold tassels, golden arm bands on the forearms, dark red trousers with gold-edged leg wraps, large golden prayer beads worn tight around the neck.
```

**Võ Đang — Thái Cực**
```
white silk tunic with deep navy blue trim, silver cloud pattern embroidered along the hem and cuffs, large silver yin-yang emblem on the back, navy sash with a small jade pendant tied tight, silver hair crown on the topknot, white trousers with navy leg wraps.
```

**Nga Mi — Phượng Hoàng**
```
white and crimson silk tunic, golden phoenix embroidered across the back and shoulder, crimson trim with gold edging, short pink silk sash, small golden phoenix hairpin in the ponytail, pale pink trousers with crimson leg wraps.
```

**Cái Bang — Long Bang**
```
dark olive green tunic with neat patches stitched in gold thread, worn brown leather belt with a polished bronze wine gourd tied tight, brown leather bracers, red cloth headband, dark brown rolled trousers with leg wraps, sturdy straw sandals.
```

**Đường Môn — Ám Ảnh**
```
black and deep purple fitted tunic with silver trim, slim leather chest harness with small flat throwing knives in sheaths, steel forearm bracers, black mask with a silver pattern covering the lower face, black trousers with purple leg wraps, black boots.
```

Lưu tên: `<Phai>_<TenBo>.fbx`, ví dụ `ThieuLam_KimCang.fbx`, `VoDang_ThaiCuc.fbx`.
