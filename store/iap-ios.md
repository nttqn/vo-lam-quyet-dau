# Mua trong ứng dụng — iOS (App Store Connect)

> Đã gắn và được duyệt cùng iOS 1.3.3 (StoreKit trong `ios_plugins/vl_storekit`).

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

Ngôn ngữ: **Vietnamese**, **English (U.S.)**, **Chinese (Traditional)**, **Korean** (từ 1.4.0). Thêm 2 ngôn ngữ sau ở mỗi sản phẩm → Localization → (+); sửa localization của sản phẩm đã duyệt không cần nộp lại build.

### ngoc_60
- VI — Display Name: `Túi Ngọc – 60 Ngọc` · Description: `60 Ngọc mua Y Phục, Bí Kíp và đồ quý.`
- EN — Display Name: `Jade Pouch – 60 Jade` · Description: `60 Jade for outfits, manuals and rare gear.`
- ZH-Hant — Display Name: `玉袋 – 60 玉` · Description: `60 玉，可購買服飾、秘笈與珍貴裝備。`
- KO — Display Name: `옥 주머니 – 옥 60` · Description: `의상, 비급, 귀한 장비를 살 수 있는 옥 60개.`

### ngoc_330
- VI — Display Name: `Hộp Ngọc – 330 Ngọc` · Description: `300 Ngọc kèm 30 Ngọc thưởng.`
- EN — Display Name: `Jade Box – 330 Jade` · Description: `300 Jade plus 30 bonus Jade.`
- ZH-Hant — Display Name: `玉盒 – 330 玉` · Description: `300 玉加贈 30 玉。`
- KO — Display Name: `옥 상자 – 옥 330` · Description: `옥 300개 + 보너스 30개.`

### ngoc_700
- VI — Display Name: `Rương Ngọc – 700 Ngọc` · Description: `600 Ngọc kèm 100 Ngọc thưởng.`
- EN — Display Name: `Jade Chest – 700 Jade` · Description: `600 Jade plus 100 bonus Jade.`
- ZH-Hant — Display Name: `玉箱 – 700 玉` · Description: `600 玉加贈 100 玉。`
- KO — Display Name: `옥 궤짝 – 옥 700` · Description: `옥 600개 + 보너스 100개.`

### ngoc_1500
- VI — Display Name: `Bảo Khố Ngọc – 1500 Ngọc` · Description: `1200 Ngọc kèm 300 Ngọc thưởng, lời nhất.`
- EN — Display Name: `Jade Treasury – 1500 Jade` · Description: `1200 Jade plus 300 bonus, best value.`
- ZH-Hant — Display Name: `玉寶庫 – 1500 玉` · Description: `1200 玉加贈 300 玉，最划算。`
- KO — Display Name: `옥 보고 – 옥 1500` · Description: `옥 1200개 + 보너스 300개, 가장 알찬 구성.`

### goi_tan_thu
- VI — Display Name: `Gói Tân Thủ` · Description: `200 Ngọc, 6.000 Vàng và nguyên liệu rèn.`
- EN — Display Name: `Starter Pack` · Description: `200 Jade, 6,000 Gold and forge materials.`
- ZH-Hant — Display Name: `新手禮包` · Description: `200 玉、6,000 金幣與鍛造材料。`
- KO — Display Name: `신규 패키지` · Description: `옥 200, 금화 6,000과 단조 재료.`

### bo_quang_cao
- VI — Display Name: `Bỏ Quảng Cáo` · Description: `Tắt quảng cáo, nhận quà QC ngay. Dùng mãi.`
- EN — Display Name: `Remove Ads` · Description: `No ads, ad rewards given instantly. Forever.`
- ZH-Hant — Display Name: `移除廣告` · Description: `去除廣告，廣告獎勵直接領取。永久有效。`
- KO — Display Name: `광고 제거` · Description: `광고 제거, 광고 보상 즉시 지급. 영구 적용.`

### mo_o_nhan_vat
- VI — Display Name: `Mở Ô Nhân Vật 5–6` · Description: `Thêm 2 ô lưu nhân vật. Mua một lần.`
- EN — Display Name: `Hero Slots 5–6` · Description: `Unlocks 2 more hero save slots. Forever.`
- ZH-Hant — Display Name: `開啟角色欄 5–6` · Description: `多開 2 個角色存檔欄。一次購買。`
- KO — Display Name: `캐릭터 슬롯 5–6 개방` · Description: `캐릭터 저장 슬롯 2개 추가. 영구 적용.`

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
