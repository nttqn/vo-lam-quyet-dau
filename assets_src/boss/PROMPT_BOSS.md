# Prompt tạo Boss Thế Giới (ChatGPT) → Meshy Pro

Game dùng **2 boss** luân phiên mỗi ngày: Đồng Giáp La Hán và Băng Phách Kiếm Quân.

Boss trong game được **phóng to 1,6 lần bằng code** và có hào quang màu riêng, nên
model cứ làm cao bình thường (~1,7 m khi Áp rig). Thứ làm boss "mới lạ" là
**dáng người và bộ giáp**: vai rộng, tay chân to, giáp, sừng, vết nứt phát sáng...

Vũ khí (côn, kiếm, song đao, ám khí) do game tự gắn vào tay — **model không cầm vũ khí**.

## Cách dùng
1. Mở chat ChatGPT mới, **đính kèm ảnh Thiếu Lâm đã làm** (giữ đúng nét vẽ).
2. Dán **PHẦN CHUNG** + **PHẦN RIÊNG** của boss.
3. Ảnh ra là tấm 3 góc → cắt thành 3 ảnh: trước / bên / sau.
4. Meshy: Image to 3D → **Nhiều góc nhìn** → 3 ảnh vào 3 ô → Meshy 7.1, bật Kết cấu, Tư thế = **T-Pose** → Tạo ra.
   Nhắm khoảng 50k tam giác như các phái.
   **Model ra bị quay đầu sang một bên** = ảnh góc bên đặt ngược phía so với ô của Meshy:
   lật ngang ảnh bên (hoặc chỉ dùng trước + sau, bỏ ảnh bên) rồi tạo lại.
5. Hoạt hình → Áp rig (chiều cao ~1.7 m) → Tải xuống: **fbx**, Mẫu bộ xương **Mixamo**,
   **Nhân vật đã được rigging** bật, **Hoạt hình** tắt, **Với Da**.
6. Lưu vào `assets_src/boss/` đúng tên dưới đây rồi báo mình — mình chép vào
   `assets/models/chars/`, game tự dùng thay cho model tạm (model phái nhuộm màu).

| Boss | Tên file | Võ công (vũ khí game gắn) |
|---|---|---|
| Đồng Giáp La Hán | `Boss_DongGiap.fbx` | Thiếu Lâm (côn) |
| Băng Phách Kiếm Quân | `Boss_BangPhach.fbx` | Võ Đang (kiếm) |

## Lưu ý để rig không lỗi
- **Phải là dáng người** (2 tay, 2 chân, 1 đầu). KHÔNG đuôi, KHÔNG cánh, KHÔNG tay thứ 3 —
  rig Mixamo không có xương cho chúng, sẽ bị kéo méo.
- Sừng, gai, giáp vai **ôm sát** người, không chĩa xa quá nửa bàn tay.
- Tay chân to là được nhưng **khe giữa 2 chân và giữa tay với thân phải rõ** ở tư thế T,
  nếu dính nhau Meshy rig sẽ kéo thịt lẫn nhau.
- Không áo choàng dài, không vạt áo chạm đất, không dải lụa bay.

## PHẦN CHUNG (dán trước mỗi boss)
```
Use the attached image as the exact art style reference: same stylized 3D game character look, same painted textures and lighting.

Character turnaround sheet of ONE character: front view, side view, back view, evenly spaced, same scale, feet on the same ground line. Full body, strict T-pose with arms straight out horizontally, palms down, fingers together, legs straight and slightly apart with a clear gap between the legs and between the arms and the body.

A giant boss monster from an ancient Chinese wuxia legend: humanoid body (two arms, two legs, one head), heroic exaggerated proportions: very broad shoulders, thick arms and legs, big hands and feet, small head relative to the body. Menacing but readable silhouette. Armor and ornaments stay close to the body. NO weapon, NO tail, NO wings, NO cape, NO long robe, NO floating parts, NO loose ribbons, NO spikes sticking far out.

Plain pure white background, flat even studio lighting, no cast shadows, no text, no labels.
```

## PHẦN RIÊNG

**Đồng Giáp La Hán** — `Boss_DongGiap.fbx`
```
An ancient bronze temple guardian statue come to life, shaped like a giant Shaolin arhat monk. Whole body made of dark polished bronze with green patina in the cracks, engraved Buddhist cloud patterns on the chest and arms, glowing amber eyes, bald head with nine raised bronze dots, heavy bronze prayer-bead necklace fused tight to the chest, short bronze loincloth-skirt over thick bronze legs, bare bronze feet.
```

**Băng Phách Kiếm Quân** — `Boss_BangPhach.fbx`
```
A frozen ancient sword lord: tall armored warrior encased in jagged pale-blue ice armor over a dark navy tunic, frost crystals growing on the shoulders and forearms, a crown of short ice shards on the head, pale grey-blue skin, long white beard frozen stiff and short, glowing icy-blue eyes, ice-plated greaves and boots, faint frost mist texture on the armor.
```
