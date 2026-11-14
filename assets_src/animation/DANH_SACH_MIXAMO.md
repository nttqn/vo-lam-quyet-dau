# Danh sách animation cần tải từ Mixamo

## Cài đặt khi bấm Download (mọi file)
- Format: **FBX Binary (.fbx)**, Skin: **Without Skin**, 30 fps, Keyframe Reduction: none
- File nào có ô **In Place** thì **tích vào**

## Mẹo tìm trên Mixamo
- Gõ **1–2 từ ngắn** (kick, block, sword, hit...). Gõ cả cụm dài thì Mixamo tìm theo cụm chính xác và ra kết quả lệch.
- Bỏ qua thẻ **chồng nhiều lớp có con số** (đó là cả pack, ví dụ "Pro Rifle Pack") và các động tác cầm súng.
- Chọn theo cột "Dùng cho" là chính. Cột "Tên hay gặp" chỉ là gợi ý; không có thì chọn cái giống nhất.
- Đổi tên file đúng cột "Tên file" rồi thả vào thư mục này. Không tìm được thì bỏ qua.

## A. Di chuyển và trạng thái
| # | Tên file | Gõ tìm | Tên hay gặp | Dùng cho |
|---|---|---|---|---|
| 1 | Walk_Fwd.fbx | walk forward | Walk Forward (tay thủ quyền) | Bước tới |
| 2 | Walk_Back.fbx | walk backward | Walk Backward (tay thủ quyền) | Lùi |
| 3 | Crouch_Idle.fbx | crouch | Crouch Idle / Crouching Idle | Ngồi thủ |
| 4 | Block.fbx | block | Center Block / Body Block | Đỡ đòn đứng |
| 5 | Block_Low.fbx | block | cái nào ngồi thấp (nếu có) | Đỡ đòn ngồi |
| 6 | Hit_Head.fbx | head hit | Head Hit / Big Head Hit | Trúng đòn đầu |
| 7 | Hit_Body.fbx | stomach | Stomach Hit / Hit Reaction | Trúng đòn bụng |
| 8 | Knockdown.fbx | knocked | Knocked Down | Bị đánh ngã |
| 9 | Getup.fbx | getting up | Getting Up / Kip Up | Đứng dậy |
| 10 | Jump.fbx | jump | Jump / Jumping (In Place) | Nhảy |
| 11 | Dodge.fbx | dodge | Dodging / Back Flip | Né |
| 12 | Victory.fbx | victory | Victory / Fist Pump | Thắng trận |
| 13 | KO.fbx | death | Falling Back Death / Dying | Thua |
| 14 | Bow.fbx | bow | Quick Formal Bow | Chào trước trận |

## B. Cước (gõ: kick)
| # | Tên file | Tên hay gặp | Dùng cho |
|---|---|---|---|
| 15 | Front_Kick.fbx | Front Kick / Kicking | Đá thẳng |
| 16 | Leg_Sweep.fbx | Leg Sweep (gõ: sweep) | Tảo Đường Thối |
| 17 | Flying_Kick.fbx | Flying Kick (In Place) | Phi Cước |

## C. Quyền, chưởng
| # | Tên file | Gõ tìm | Tên hay gặp | Dùng cho |
|---|---|---|---|---|
| 18 | Jab.fbx | jab | Lead Jab | Đòn tay nhanh |
| 19 | Cross.fbx | punch | Cross Punch / Punching | Đòn tay mạnh |
| 20 | Uppercut.fbx | uppercut | Uppercut | Đấm hất |
| 21 | Palm.fbx | magic attack | Standing 1H Magic Attack 01 | Đẩy chưởng 1 tay |
| 22 | Double_Palm.fbx | magic attack | Standing 2H Magic Attack 01 | Đẩy chưởng 2 tay |
| 23 | Grab.fbx | throw | Hip Throw / Judo (ném người) | Cầm Nã Thủ |

## D. Kiếm và côn (gõ: sword, melee)
| # | Tên file | Tên hay gặp | Dùng cho |
|---|---|---|---|
| 24 | Slash_H.fbx | Stable Sword Outward Slash | Chém ngang |
| 25 | Slash_Hi.fbx | Stable Sword Inward Slash | Chém chéo |
| 26 | Thrust.fbx | động tác đâm thẳng (Sword And Shield Attack...) | Đâm kiếm, chọc côn |
| 27 | Rising.fbx | động tác chém hất lên (Sword And Shield Slash...) | Chém hất |
| 28 | Spin_Attack.fbx | Great Sword High Spin Attack / Standing Melee Attack 360 | Xoay người chém |
| 29 | Overhead.fbx | Standing Melee Attack Downward | Bổ từ trên xuống |

## E. Ám khí và chiêu
| # | Tên file | Gõ tìm | Tên hay gặp | Dùng cho |
|---|---|---|---|---|
| 30 | Throw.fbx | throw | Throw / Throw Object | Phóng ám khí |
| 31 | Cast.fbx | spell | Standing 2H Cast Spell 01 / Magic Spell Casting | Tung chiêu |
| 32 | Power_Up.fbx | power | Power Up | Vận công, buff |

## F. Tuỳ chọn
- Dáng đi riêng từng phái: `NgaMi_Walk_Fwd.fbx`, `ThieuLam_Walk_Back.fbx`...
- Cái Bang túy quyền (gõ: drunk): `CaiBang_Drunk_Idle.fbx`, `CaiBang_Drunk_Walk.fbx`

## G. Chiêu riêng cho từng phái — ĐÃ TẢI ĐỦ VÀ NỐI VÀO GAME (14/11/2026)
Cách tải giống phần đầu: **FBX Binary, Without Skin, 30 fps, tích In Place nếu có**.
Thiếu file nào thì chiêu đó tự quay về động tác dùng chung (AnimMap.FALLBACK), game không lỗi.

| Tên file | Clip Mixamo đã chọn | Dùng cho |
|---|---|---|
| Side_Kick.fbx | Side Kick | Tiến + Cước (mọi phái) |
| Cast.fbx | Standing 2H Magic Area | Phổ Độ Liên Hoa, Vạn Độc Thiên La |
| Power_Up.fbx | Sword And Shield Power Up | Buff: Kim Cang Hộ Thể, Tọa Vong, Tửu Thần, Tâm Pháp Việt Võ |
| ThieuLam_Quad_Punch.fbx | Quad Punch | La Hán Quyền |
| ThieuLam_Roar.fbx | Roar | Sư Tử Hống |
| ThieuLam_Smash.fbx | Smash (search "staff") | Đạt Ma Kim Thân |
| (Spin_Attack.fbx có sẵn) | | Phong Ma Côn Pháp (xoay 1 vòng) |
| VoDang_Sword_Combo.fbx | One Hand Sword Combo | Thái Cực Kiếm |
| VoDang_Jump_Attack.fbx | Jump attack (kiếm) | Thê Vân Tung |
| NgaMi_Sword_Fast.fbx | Dual Weapon Combo | Phất Vân Thủ, Song Yến Phi (đòn tay), Lưu Thủy Kiếm |
| NgaMi_Pray.fbx | Pray | Phật Quang Phổ Chiếu |
| CaiBang_Drunk_Idle.fbx | Drunk Idle Variation | Thế đứng khi đang có buff Tửu Thần |
| CaiBang_Drunk_Walk.fbx | Drunk Walk | Dáng đi khi có Tửu Thần; chân của Túy Quyền (tay = Punch Combo) |
| CaiBang_Punch_Combo.fbx | Punch Combo | Phi Long Tại Thiên, tay của Túy Quyền |
| DuongMon_Toss.fbx | Toss Grenade | Phi Đao Tam Liên, Đoạt Mệnh Độc Châm |
| DuongMon_Grenade.fbx | Grenade Throw (vung cao) | Lôi Hỏa Đạn |
| DuongMon_Throw2.fbx | Grenade Throw (khom thấp) | Bạo Vũ Lê Hoa |
| Vovinam_Elbow.fbx | Punch To Elbow Combo | Liên Hoàn Đấm Chỏ |
| Vovinam_Knee.fbx | Flying Knee Punch Combo | Lên Gối Hạ Chỏ |
| Vovinam_Kick_1.fbx | Martelo 3 | Đá Tạt Vòng Cầu; cú 1 của Liên Hoàn Đòn Chân |
| Vovinam_Kick_2.fbx | Chapa 2 | Đá Đạp Tống; cú 2 của Liên Hoàn Đòn Chân (cú 3 = Side_Kick) |

Không dùng: Hurricane Kick.fbx (xoay 4 vòng, giữ file nhưng không map).
Kiểm tra clip mới: `tools/spin_check.gd` (độ xoay hông), `tools/peak_check.gd` (lúc tay/chân vươn xa nhất).

### Ghi chú
- Thứ tự ưu tiên: **G1 trước** (sửa được nhiều chiêu nhất), sau đó tới phái bạn hay chơi.
- Không cần tải đủ một lần. Thả file nào vào thì báo, mình nối chiêu đó với clip mới.
- **Tránh** các clip xoay người liên tục nhiều vòng (Hurricane Kick, Tornado): khi game nén vào khoảng nửa giây trông như con quay.
