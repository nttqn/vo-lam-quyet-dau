# Võ Lâm Quyết Đấu

Game đối kháng võ lâm 2.5D (Godot 4.7, 3D low-poly dựng bằng code). Chọn 1 trong 5 môn phái
(Thiếu Lâm, Võ Đang, Nga Mi, Cái Bang, Đường Môn), cộng điểm, học võ công, sắm trang bị, rồi
hành tẩu giang hồ qua 7 vùng đất / 42 trận, Lôi Đài liên thắng và Luyện Công.

## Cấu trúc
- `scripts/combat/` — logic đấu thuần (Fighter, FightSim, FightAI), 60 tick/s, không phụ thuộc node.
- `scripts/render/` — Body (nhân vật khớp xương từ primitive), Poses, Arena (8 sân khấu), Fx.
- `scripts/data/` — môn phái & chiêu thức, chỉ số, trang bị, hành trình, NPC.
- `scripts/ui/` — các màn hình (UI dựng bằng code).
- `tools/` — `sim.gd` (AI đấu AI cân bằng), `sim_detail.gd`, `gen_audio.gd` (tổng hợp âm thanh), ảnh test.

## Lệnh hữu ích
```
godot --headless --path . --script res://tools/sim.gd -- --n=16 --lvl=20   # cân bằng phái
godot --headless --path . --script res://tools/gen_audio.gd               # tạo lại âm thanh
godot --headless --fixed-fps 60 --path . -- --flowtest                     # chạy thử toàn luồng
godot --path . -- --screen=hub --shot=hub.png                              # chụp màn hình
```
APK được build bởi GitHub Actions (`.github/workflows/android.yml`).
