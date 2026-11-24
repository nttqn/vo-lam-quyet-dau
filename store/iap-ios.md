# Mua trong ứng dụng — iOS (App Store Connect)

> **CHƯA ĐÍNH KÈM VÀO BẢN NÀO** cho tới khi game có mã StoreKit cho iOS.
> `scripts/iap.gd` hiện chỉ có Google Play Billing; trên iPhone cửa hàng đóng
> ("Cửa hàng trên iPhone/iPad sẽ có trong bản sau"). Nộp IAP kèm một build
> không mua được → Apple từ chối (2.1). Tạo sẵn sản phẩm ở trạng thái
> "Ready to Submit" thì không sao.

Nơi tạo: App Store Connect → app Võ Lâm Quyết Đấu → **Monetization → In-App Purchases** → (+).
Product ID giữ **giống hệt Android** (không trùng với Kiếm Hiệp, bên đó dùng tiền tố `kh_`),
để mã iOS dùng chung `scripts/iap.gd`. Product ID là duy nhất trong cả tài khoản và
**không đổi/xóa dùng lại được** sau khi tạo.

Giới hạn ASC: Reference Name ≤ 64, **Display Name ≤ 30**, **Description ≤ 45** ký tự.
Ảnh: `store/iap-ios/<id>.png` (1024×1024, không trong suốt, không chữ) — ô "App Store Promotion" (tùy chọn).
Review Screenshot (bắt buộc, mỗi sản phẩm một ảnh): `store/iap-ios-review/<Product ID>.png` (2622×1206, màn Bảo Khố, gói đó viền vàng, các gói khác mờ, chữ "App Store"). Vẽ lại: `Godot --path . --resolution 2622x1206 -- --screen=topup --asios --focus=<id> --shot=<file> --delay=60`.

## Bảng sản phẩm

| Product ID | Type | Reference Name | Giá Android | Giá iOS gợi ý (US) |
|---|---|---|---|---|
| ngoc_60 | Consumable | Jade 60 | 22.000 ₫ | 0.99 USD |
| ngoc_330 | Consumable | Jade 330 | 109.000 ₫ | 4.99 USD |
| ngoc_700 | Consumable | Jade 700 | 219.000 ₫ | 9.99 USD |
| ngoc_1500 | Consumable | Jade 1500 | 449.000 ₫ | 19.99 USD |
| goi_tan_thu | Consumable | Starter Pack | 49.000 ₫ | 1.99 USD |
| bo_quang_cao | Non-Consumable | Remove Ads | 69.000 ₫ | 2.99 USD |
| mo_o_nhan_vat | Non-Consumable | Hero Slots 5-6 | 49.000 ₫ | 1.99 USD |

Giá: trong Price Schedule chọn **Base Country = Vietnam** rồi lấy mức giá VND gần nhất với cột Android;
Apple tự quy đổi các nước khác. Availability: tất cả quốc gia đang bán app.
Gói Tân Thủ là Consumable (game tự giới hạn mỗi nhân vật một lần, như Android).
Non-Consumable bắt buộc có nút **Khôi phục giao dịch** (Restore Purchases) trong game — phải làm cùng StoreKit.

## Localization

Thêm 2 ngôn ngữ: **Vietnamese** và **English (U.S.)**.

### ngoc_60
- VI — Display Name: `Túi Ngọc – 60 Ngọc` · Description: `60 Ngọc mua Y Phục, Bí Kíp và đồ quý.`
- EN — Display Name: `Jade Pouch – 60 Jade` · Description: `60 Jade for outfits, manuals and rare gear.`

### ngoc_330
- VI — Display Name: `Hộp Ngọc – 330 Ngọc` · Description: `300 Ngọc kèm 30 Ngọc thưởng.`
- EN — Display Name: `Jade Box – 330 Jade` · Description: `300 Jade plus 30 bonus Jade.`

### ngoc_700
- VI — Display Name: `Rương Ngọc – 700 Ngọc` · Description: `600 Ngọc kèm 100 Ngọc thưởng.`
- EN — Display Name: `Jade Chest – 700 Jade` · Description: `600 Jade plus 100 bonus Jade.`

### ngoc_1500
- VI — Display Name: `Bảo Khố Ngọc – 1500 Ngọc` · Description: `1200 Ngọc kèm 300 Ngọc thưởng, lời nhất.`
- EN — Display Name: `Jade Treasury – 1500 Jade` · Description: `1200 Jade plus 300 bonus, best value.`

### goi_tan_thu
- VI — Display Name: `Gói Tân Thủ` · Description: `200 Ngọc, 6.000 Vàng và nguyên liệu rèn.`
- EN — Display Name: `Starter Pack` · Description: `200 Jade, 6,000 Gold and forge materials.`

### bo_quang_cao
- VI — Display Name: `Bỏ Quảng Cáo` · Description: `Tắt quảng cáo, nhận quà QC ngay. Dùng mãi.`
- EN — Display Name: `Remove Ads` · Description: `No ads, ad rewards given instantly. Forever.`

### mo_o_nhan_vat
- VI — Display Name: `Mở Ô Nhân Vật 5–6` · Description: `Thêm 2 ô lưu nhân vật. Mua một lần.`
- EN — Display Name: `Hero Slots 5–6` · Description: `Unlocks 2 more hero save slots. Forever.`

## Review Notes (dán vào ô Review Notes của từng sản phẩm)

```
Open the game, create or pick a hero, then tap "Bảo Khố" (Treasury) on the main hub.
All packs are listed there. Jade packs and the Starter Pack are consumable; Remove Ads
and Hero Slots 5-6 are non-consumable and can be restored with "Khôi phục giao dịch"
(Restore Purchases) at the bottom of the Treasury screen.
```

## Trước khi nộp version có IAP

1. Mã StoreKit cho iOS trong `scripts/iap.gd` + nút Khôi phục giao dịch — chưa làm.
2. Paid Apps Agreement + thuế + ngân hàng đã "Active" trong ASC → Business.
3. Mỗi sản phẩm: có Review Screenshot → trạng thái "Ready to Submit".
4. Trang version: mục **In-App Purchases and Subscriptions** → chọn cả 7 sản phẩm, nộp cùng build.
