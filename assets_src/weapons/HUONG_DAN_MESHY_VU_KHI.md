# Model vũ khí 3D bằng Meshy

Mỗi loại vũ khí 3 hình dáng theo bậc: **dáng 1** = bậc Mộc, Đồng · **dáng 2** = Thiết, Cương, Ngân · **dáng 3** = Huyền, Thiên.
Thiếu dáng nào thì game dùng file `<loai>.glb` (nếu có), không có nữa thì dùng vũ khí dựng sẵn.

| Phái | Loại | Tên file (dáng 1 / 2 / 3) | Ghi chú |
|---|---|---|---|
| Thiếu Lâm | Côn | `staff_1.glb`, `staff_2.glb`, `staff_3.glb` | game kéo dài ~1,8 m |
| Võ Đang | Kiếm | `sword_1.glb` … `sword_3.glb` | ~1 m |
| Nga Mi | Song kiếm | `dual_blade_1.glb` … | chỉ làm **một** thanh, game tự nhân đôi hai tay |
| Đường Môn | Chủy thủ | `dagger_1.glb` … | một con dao găm |
| Cái Bang | Hộ thủ | (để sau) | đeo ở cẳng tay, cần cách gắn riêng |

## Bước 1: ảnh mẫu bằng ChatGPT
Dán prompt chung + mô tả từng món (lấy từ PROMPT_VU_KHI.md, đúng bậc của dáng đó):
```
Single weapon for a 3D game model reference: <mô tả vũ khí>. Standing perfectly straight up and vertical, handle at the bottom, tip at the top, shown flat from the front, the whole weapon fully visible, centered. Stylized painted look matching a wuxia game. Plain pure white background, even studio lighting, no shadow, no text, no hands.
```
Ví dụ kiếm dáng 3: `<mô tả vũ khí>` = `a heavenly Chinese jian sword in gold and white jade with cloud engravings, taiji emblem on the guard and a long silk tassel`.

## Bước 2: Meshy
1. **Image to 3D**, đưa ảnh vào (1 ảnh là đủ; có ảnh nhìn ngang thì bật Nhiều góc nhìn).
2. Mô hình **Meshy 7**, bật **Kết cấu (Texture)**, số mặt thấp: **5.000–10.000** (vũ khí nhỏ, không cần nhiều).
3. **Không** gắn xương, **không** hoạt hình.
4. Tải xuống định dạng **GLB**.
5. Đặt tên đúng bảng trên, thả vào `assets_src/weapons/`.

Trong Meshy, nếu vũ khí bị nằm ngang hay chúc ngược, xoay lại cho **đứng thẳng, chuôi ở dưới** trước khi tải (nút xoay trong khung xem). Game tự chỉnh kích thước và tự đặt vào tay.
