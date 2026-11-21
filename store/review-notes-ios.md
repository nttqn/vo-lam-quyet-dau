# App Review Notes (iOS): reply to Guideline 2.1(a) Information Needed

Second 2.1 reply (2026-11-21). Apple asked for a demo account with access to all features.
Build 1.0.1 (3): no chat, no in-app purchases on iOS.

Setup, done once:
1. `godot --headless --path . --script res://tools/review_demo.gd -- <out.json>` makes the demo
   hero: level 60, all story stages cleared, max skills, +15 gear.
2. `node tools/review_demo.mjs <email> <password> <out.json>` creates the Firebase email/password
   account and puts that hero in its cloud slot "Ô lưu 3".
3. App Store Connect → the version → App Review Information:
   - tick "Sign-in required";
   - fill User name and Password with the demo account;
   - paste the NOTES block below into Notes.
4. Reply to the App Review message with the REPLY block below.

The password is never stored in this repo (the repo is public).

---

NOTES (App Review Information → Notes)

DEMO ACCOUNT
The User name and Password above are a demo account. It holds a level-60 hero named "Khach Thu"
with every story stage cleared and all skills and equipment maxed, so every feature is unlocked.

HOW TO SIGN IN (about 30 seconds)
1. Launch the app. On the title screen, tap "Tài khoản" (Account), at the bottom.
2. Enter the demo e-mail and password, then tap "Đăng nhập" (Sign in).
3. Tap "Đóng" (Close). The demo hero appears in the third save slot ("Ô lưu 3").
4. Tap "Vào game" (Play) on that slot. The hub opens.

WHERE THE FEATURES ARE
- Story ("Hành Tẩu Giang Hồ"): the gold banner at the top right of the hub. All regions are open.
- Trial Tower, Duels (other players' heroes, AI-controlled), Arena, Training: the four tiles.
- Dungeons ("Phó Bản"): the tile below them.
- Character, skills, equipment, shop, outfits, missions, leaderboard, settings: the icon row at
  the bottom of the hub.
- Fight controls: virtual stick on the left; attack / block / dodge / technique buttons on the
  right; the pause button is at the top.

OTHER NOTES
- A demo account is optional for players: without signing in, the game creates an anonymous
  guest account on first launch, and the player starts a new hero from level 1.
- Account deletion: title screen → "Tài khoản" → "Xóa tài khoản" (Delete account), tap twice.
  Please do not delete the demo account itself during the review.
- There are no in-app purchases in this iOS version. Ads are Google AdMob.
- There is no chat or other user-generated content in this version; hero names are the only
  text players enter.
- The interface is in Vietnamese.

---

REPLY (Reply to App Review)

Hello,

Thank you for the review. We have added a demo account in App Review Information
(User name and Password, with "Sign-in required" ticked). It holds a level-60 hero with
every feature unlocked.

To use it: on the title screen tap "Tài khoản" (Account), enter the e-mail and password,
tap "Đăng nhập" (Sign in), then "Đóng" (Close). The demo hero appears in the third save
slot; tap "Vào game" (Play). Step-by-step notes, including where each feature is, are in
the Notes field.

Best regards
