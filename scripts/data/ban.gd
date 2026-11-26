class_name Ban
extends RefCounted
## Khóa tài khoản (1.3.1): ban/{uid} created by hand in the Firebase console.
## Fields, all optional: why (string, shown to the player), until (timestamp;
## missing = permanent). firestore.rules refuses every write of a banned uid to
## rank, duel_*, wb_* and chat, for every app version. This side, for 1.3.1+:
## - check() reads the doc (at most every CHECK_GAP s) and keeps the result in
##   settings["ban"], so it holds offline and across launches;
## - on a new ban it deletes the player's own rows (rank, this season's Tỉ Võ
##   shadow, today's Boss Thế Giới), which the rules let the owner do;
## - publish paths skip while active(), and the screens show text().
## Offline play, cloud saves and the story are untouched.
## Console: tools/ban_check.mjs <uid> lists what a uid still has on the boards.

const CHECK_GAP := 600.0
static var _checked_at := -1e9
static var _busy := false

static func state() -> Dictionary:
	var s = Game.settings.get("ban", {})
	return s if s is Dictionary else {}

## Unix time the ban ends, 0 = permanent.
static func until() -> int:
	return int(state().get("until", 0))

static func active() -> bool:
	var s := state()
	if s.is_empty():
		return false
	var u := until()
	return u == 0 or u > int(GameClock.now())

## One paragraph for the board screens and chat.
static func text() -> String:
	var why := str(state().get("why", "")).strip_edges()
	var u := until()
	var t := L.t("Tài khoản này đã bị khóa khỏi Bảng xếp hạng, Tỉ Võ, Boss Thế Giới và Kênh Thế Giới")
	if u > 0:
		var d := Time.get_date_dict_from_unix_time(u + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
		t += L.f(" đến %02d/%02d/%d.", [int(d.day), int(d.month), int(d.year)])
	else:
		t += L.t(" vĩnh viễn.")
	if why != "":
		t += L.f(" Lý do: %s.", why.trim_suffix("."))
	return t + L.t(" Bạn vẫn chơi cốt truyện và các chế độ khác bình thường.")

## Red notice for the board screens.
static func notice(size := 17) -> Label:
	var l := UI.label(text(), size, Color(1.0, 0.5, 0.45), UI.bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Reads ban/{uid}. force skips the CHECK_GAP throttle.
static func check(force := false) -> void:
	if _busy or not Cloud.enabled() or Cloud.uid == "":
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _checked_at < CHECK_GAP:
		return
	_busy = true
	_checked_at = now
	var r: Dictionary = await Cloud.fetch_doc("ban/" + Cloud.uid)
	_busy = false
	var code := int(r.code)
	if code == 404:
		if not state().is_empty():
			Game.settings.erase("ban")   # lifted in the console
			Game.save_settings()
		return
	if code != 200:
		return   # offline or refused: keep what we knew
	var f: Dictionary = r.fields
	var s := {"why": str(f.get("why", "")).substr(0, 120), "until": _unix(str(f.get("until", "")))}
	var was := active()
	Game.settings["ban"] = s
	Game.save_settings()
	if active() and not was:
		purge()

## Deletes this account's rows from the shared boards.
static func purge() -> void:
	if not Cloud.enabled():
		return
	for i in Game.SLOTS:
		await Cloud.delete_doc(Ranks.COLLECTION, "_%d" % i)
	await Cloud.delete_doc(Duel.collection(), "")
	for i in Game.SLOTS:
		await Cloud.delete_doc(WBoss.collection(), "_%d" % i)

## Firestore timestamp "2026-12-01T00:00:00Z" (or with fractions / offset Z) to unix; 0 if empty.
static func _unix(ts: String) -> int:
	if ts == "":
		return 0
	var base := ts.substr(0, 19)
	var t := int(Time.get_unix_time_from_datetime_string(base))
	return t if t > 0 else 0
