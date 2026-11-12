# Bối cảnh, cảnh vật, menu: prompt ChatGPT + Meshy

Thả file đúng tên vào đúng chỗ là game tự dùng, không cần sửa code:
- Tranh nền → `assets/art/bg_<bối cảnh>.png`
- Đồ vật 3D → `assets/models/props/<tên>.glb`
- Logo → `assets/art/logo.png`
(Hoặc gửi mình trong `assets_src/scenery/`, mình chép và kiểm tra giúp.)

Bối cảnh (theme) trong game: `temple` (chùa, Thiếu Thất), `bamboo` (rừng trúc), `river` (bến sông),
`snow` (Thiên Sơn), `desert` (đại mạc), `demon` (Ma giáo), `peak` (đỉnh núi, màn hình chính), `night` (đêm).

## 1. Tranh nền (ChatGPT), 8 tấm
Tranh treo xa phía sau sàn đấu, game lặp nối tiếp hai bên nên cần **nối liền được ở mép trái/phải**.
Phần dưới khoảng 1/3 tranh bị tường và sàn che, nên chỉ cần mặt đất mờ sương.

**Phần chung:**
```
Wide landscape background painting for a Vietnamese wuxia 2.5D fighting game, painted ink-wash style with rich color and soft atmospheric depth. Eye-level view, the horizon at one third from the bottom. Only distant scenery (far mountains, sky, clouds, distant buildings), nothing close to the viewer, no characters, no animals, no text. The bottom third is soft misty ground. Seamless left and right edges so the image can be repeated side by side. Canvas 1536x1024.
```

| Tên file | Thêm vào sau phần chung |
|---|---|
| `bg_temple.png` | `Shaolin mountain temple: misty green mountains, distant temple roofs and a tall pagoda among pine trees, warm morning light, pale blue sky.` |
| `bg_bamboo.png` | `Deep bamboo forest: layers of tall green bamboo fading into white mist, soft green light, a distant hazy mountain.` |
| `bg_river.png` | `Great river ferry: wide calm river, distant sails and wooden boats, far green hills, golden sunset sky reflected on the water.` |
| `bg_snow.png` | `Snowy Tian Shan peaks: jagged white mountains, glaciers, snow-covered pine forest far away, pale blue cold sky, light snowfall.` |
| `bg_desert.png` | `Desert frontier: rolling golden sand dunes, a ruined ancient fortress city on the horizon, hot hazy orange sky.` |
| `bg_demon.png` | `Demon cult stronghold: dark volcanic canyon, black cliffs, a sinister fortress with red lanterns far away, blood red sky with dark clouds and a crescent moon.` |
| `bg_peak.png` | `Martial arts summit above the clouds: sharp mountain peaks rising from a sea of clouds, a small pavilion on a far peak, pink and purple sunset sky.` |
| `bg_night.png` | `Moonlit night: dark blue mountains, a huge full moon, distant pagoda silhouettes and a few warm lantern lights, starry sky.` |

## 2. Đồ vật 3D (ChatGPT → Meshy)
**Bước 1, ChatGPT** (mỗi đồ vật một ảnh):
```
Single <đồ vật> for a 3D game model reference, stylized painted wuxia game style, full object visible, three-quarter front view, standing upright on flat ground, plain pure white background, even studio lighting, no shadow, no text, no people.
```
**Bước 2, Meshy:** Image to 3D → Meshy 7, bật Kết cấu, số mặt **3.000–8.000** (chùa tối đa ~15.000), không gắn xương, không hoạt hình, tải **GLB**, đặt tên theo bảng.
Game tự chỉnh chiều cao và đặt đúng chỗ. Đồ vật phải **đứng thẳng, đáy nằm trên mặt đất**.

| Tên file | `<đồ vật>` | Dùng ở |
|---|---|---|
| `pagoda.glb` | `three-story Chinese wooden pagoda with red pillars, dark grey tiled upturned roofs and a golden finial` | chùa, đêm |
| `pagoda_snow.glb` | `two-story mountain temple pagoda with dark red walls and roofs covered in thick snow` | Thiên Sơn |
| `pagoda_demon.glb` | `sinister three-story black pagoda of a demon cult with blood red trim, spiky roof tips and red lanterns` | Ma giáo |
| `gate.glb` | `Chinese paifang memorial gate with two red wooden pillars and a dark tiled roof` | đại mạc (bản thường) |
| `gate_desert.glb` | `weathered sandstone fortress gate of an abandoned desert city` | đại mạc |
| `lantern.glb` | `tall wooden lantern post with a red paper lantern hanging at the top` | chùa |
| `lantern_demon.glb` | `black iron lantern post with a glowing red lantern and chains` | Ma giáo |
| `tree.glb` | `stylized broadleaf tree with a round lush green canopy` | chùa, sông |
| `pine.glb` | `stylized mountain pine tree with layered dark green needles` | (dự phòng) |
| `pine_snow.glb` | `stylized pine tree with layered needles covered in thick snow` | Thiên Sơn |
| `rock.glb` | `mossy grey boulder with rounded edges` | rừng trúc, chùa |
| `rock_snow.glb` | `grey boulder with snow on top` | Thiên Sơn |
| `rock_desert.glb` | `sandstone rock, warm orange, wind-worn` | đại mạc |
| `rock_demon.glb` | `jagged black volcanic rock with faint red cracks` | Ma giáo |
| `boat.glb` | `small Chinese wooden river boat with a curved bamboo roof cover` | bến sông |
| `wall.glb` | `section of a crumbling sandstone fortress wall, about as wide as it is tall` | đại mạc |
| `brazier.glb` | `large black iron fire bowl brazier on three legs` | Ma giáo |
| `incense.glb` | `bronze temple incense burner urn with incense sticks` | chùa |

Nên làm trước bộ **chùa** (`pagoda`, `lantern`, `tree`, `incense`, `rock`): dùng ở màn tạo nhân vật, sảnh và vùng 1.

## 3. Menu
**Logo** (`assets/art/logo.png`, nền trong suốt, thay chữ tiêu đề ở màn hình chính):
```
Game logo calligraphy "Võ Lâm Quyết Đấu" in bold Vietnamese brush calligraphy, gold ink with a dark red outline and a subtle crossed sword behind the text, wuxia style, centered, transparent background (PNG), no other text. Canvas 1536x1024.
```
Lưu ý: chữ tiếng Việt có dấu, ChatGPT hay viết sai dấu; kiểm tra kỹ "Võ Lâm Quyết Đấu" trước khi dùng.

Màn hình chính, bản đồ, tạo nhân vật, thoại đều dùng bối cảnh 3D phía trên, nên làm đẹp tranh nền + đồ vật là các menu đẹp theo.
