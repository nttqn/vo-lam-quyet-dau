# App Review Notes (iOS) — reply to Guideline 2.1 Information Needed

Paste the block below into App Store Connect → the version → App Review Information → Notes.
Put the screen-recording link (or attach the video) where it says <VIDEO LINK>.
Written for build 1.0.1 (3): no chat, no in-app purchases on iOS. If a newer build
(world chat) is submitted, the recording must also show Report / Block on a chat message.

---

1. SCREEN RECORDING
Recorded on a physical iPhone (latest iOS), starting from app launch: <VIDEO LINK>
It shows: launch → title screen → creating a hero (sect + name) → hub → a story fight →
rewards → Tower / Arena / Dungeon → leaderboard and Duels (other players' heroes) →
Account panel (optional email link, sign out, Delete account).

2. PURPOSE AND AUDIENCE
Vo Lam Quyet Dau is a single-player, one-on-one 3D wuxia (martial-arts) fighting game for
players aged 9+ who enjoy fighting and martial-arts stories, mainly Vietnamese speakers
(the interface is in Vietnamese). The player picks one of five martial sects, fights through
a 42-fight story, the Trial Tower, Arena and Dungeons, upgrades weapons and outfits, and can
challenge AI-controlled copies of other players' heroes in a weekly Duel ranking.
Fights are stylised martial arts with no blood.

3. HOW TO ACCESS THE FEATURES
- No login or demo account is needed. On first launch the game silently creates an
  anonymous guest account, so every feature is available immediately.
- Tap an empty slot → choose a sect and a name → Start. The hub opens.
- Controls in a fight: virtual stick on the left, attack / block / dodge / technique buttons
  on the right. The pause button is at the top.
- Story: the gold banner at the top of the hub. Tower, Arena, Dungeon and Duels: the four mode
  tiles. Leaderboard, character, skills, forge, settings: the bottom icon row.
- Optional account: title screen → "Tài khoản" (Account). The player may link an email and
  password only to back up saves to the cloud.
- Account deletion: title screen → "Tài khoản" → "Xóa tài khoản" (Delete account). It deletes
  the account, the cloud saves, the leaderboard entries and the Duel entry (tap twice to confirm).
- Leaderboard privacy: Leaderboard screen → "Ẩn tôi khỏi bảng" hides the player from the
  leaderboard and from Duels.
- There are no in-app purchases in this iOS version. Ads are Google AdMob: optional rewarded
  ads (double rewards, revive), and from hero level 10 an occasional interstitial between
  screens (never during a fight).
- There is no chat or other user-generated content in this version; hero names are the only
  text players enter.

4. EXTERNAL SERVICES
- Google Firebase Authentication (anonymous guest account, optional email/password link).
- Google Cloud Firestore (cloud saves, leaderboard, weekly Duel ranking).
- Google AdMob and Google User Messaging Platform (ads and consent).
No AI services, no payment processors, no other data providers.

5. REGIONAL DIFFERENCES
None. The app has the same features and content in every region.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. All characters, story and art are original to the developer. Sound effects
are CC0 recordings and one free voice pack used under its licence (credited in Settings).
