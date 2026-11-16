# Prompt ChatGPT: icon + feature graphic (Võ Lâm Quyết Đấu)

Lưu ảnh ChatGPT vào `store/src/` (icon_raw.png, feature_raw.png) rồi nhờ Claude cắt/ghép:
icon → 512x512 full-bleed, feature → 1024x500 + chèn logo `assets/art/logo.png`.

## 1. Icon (khung vuông 1024x1024)

```
Mobile game app icon, square 1:1, full-bleed artwork filling the entire canvas edge to edge
(no rounded corners, no border, no frame, no text, no letters, no logo).

Subject: a young Chinese wuxia swordsman in a flowing white-and-silver Taoist robe with a red sash,
shown from the chest up in a dynamic 3/4 view, holding a gleaming straight jian sword diagonally
across the frame, the blade catching a bright golden glint. Determined, intense eyes looking at the
viewer, black hair tied in a topknot, a few strands blowing in the wind.

Background: a giant setting sun behind him, layered misty mountain peaks in deep crimson and
orange, a few ink-wash brush strokes and drifting cherry/plum petals.

Style: polished stylized 3D game art like a premium mobile action game icon, semi-realistic
cel-shaded rendering, strong rim light from the sun, high contrast, warm red-orange-gold palette
with the white robe popping out. Bold, clean silhouette that is still readable at 48x48 px.
Character large and centered, face and sword fill most of the icon.
```

Biến thể (nếu muốn thử thêm):
- **Hai kiếm khách đối đầu:** thay đoạn Subject bằng
  `two wuxia fighters clashing swords in the center, sparks flying where the blades meet, one in white robe, one in black robe, seen in silhouette against the sun`
- **Kiếm + chữ Hán:** `a single jian sword planted in a rock, a large red ink brush circle (enso) behind it` (tối giản, kiểu biểu tượng).

## 2. Feature graphic (khung ngang, sẽ cắt 1024x500)

Google Play phủ nút Play/tiêu đề lên một phần ảnh, và ChatGPT viết dấu tiếng Việt hay sai
→ **không cho AI viết chữ**, để trống khoảng giữa-trên cho logo thật.

```
Wide cinematic key art banner for a mobile wuxia fighting game, landscape 16:9 (will be cropped
to 1024x500, keep all important content inside the central horizontal band).
NO text, NO letters, NO logo, NO watermark.

Scene: two martial artists facing off for a duel on a stone plaza at the edge of a cliff.
Left: a young swordsman in a white-and-silver Taoist robe with a red sash, sword drawn, low stance.
Right: a bald Shaolin monk in saffron-yellow robes with a wooden staff, poised to strike.
Between them: an energy clash of qi — golden sparks, swirling wind, scattered petals and leaves.
Leave the upper-center area relatively calm (sky and sun glow) for a title logo to be placed later.

Background: dramatic sunset sky in orange and crimson, huge sun low on the horizon, layered misty
mountain peaks, twisted pine trees on rocks, a distant pagoda on a peak, ink-wash painting
textures blended into the clouds.

Style: polished stylized 3D game key art, semi-realistic cel-shaded, cinematic lighting with
strong backlight and rim light, high contrast, rich warm palette, epic and energetic composition,
both characters full-body and clearly visible, similar to premium Asian mobile action game banners.
```

Biến thể **ngũ phái** (khoe nhiều phái):
```
...Scene: five martial artists from different sects posed heroically in a V-formation on a cliff:
center a white-robed swordsman, a bald Shaolin monk with a staff, a female swordswoman in pale
blue-white robes with twin swords, a ragged beggar-sect fighter with a bamboo staff and wine gourd,
and a masked assassin in dark green with throwing daggers...
```
(Không đưa Vovinam vào ảnh store – phái ẩn.)

## Mẹo
- Không ưng → nói "same image but ..." để sửa trong cùng cuộc chat thay vì sinh lại từ đầu.
- Icon: kiểm tra bằng cách thu nhỏ ảnh còn ~48px, vẫn nhận ra người + kiếm là đạt.
- Có thể đính kèm ảnh nhân vật Meshy/screenshot game vào ChatGPT và thêm
  "match the character designs in the attached image" để nhân vật trong ảnh giống trong game
  (Play cấm ảnh quảng cáo sai lệch quá xa so với gameplay).
