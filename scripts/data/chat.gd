class_name Chat
extends RefCounted
## Kênh Thế Giới: one public chat room for every player, on Firestore (REST,
## through Cloud). The server's rules (firestore.rules) are what enforce the
## limits below; the client mirrors them so the player sees why.
##
## - chat/{id}: uid, name, sect, level, text, at (server time).
## - chatlast/{uid}: at = when that player last sent. Written in the same
##   commit as the message; the rules refuse it within COOLDOWN of the last.
## - chatban/{uid}: created by hand in the Firebase console to mute someone.
## - chatreport/{msgId}_{uid}: reports, read in the console.
##
## The chat screen polls for messages newer than the last one it has, so an
## idle poll costs one document read.

const COLLECTION := "chat"
const MAX_LEN := 120
const SHOWN := 60           # newest messages loaded on open / kept in the list
const COOLDOWN := 20.0      # seconds between two messages of one player (rules: 20 s)
const MIN_LEVEL := 5        # heroes below this can read but not write
const POLL := 5.0           # seconds between polls while the screen is open

const RULES_TEXT := "Kênh Thế Giới là nơi mọi hiệp khách cùng trò chuyện.\n\n" \
	+ "•  Không chửi bới, xúc phạm, phân biệt đối xử hay quấy rối người khác.\n" \
	+ "•  Không quảng cáo, lừa đảo, mua bán tài khoản.\n" \
	+ "•  Không chia sẻ số điện thoại, địa chỉ hay thông tin cá nhân.\n\n" \
	+ "Chạm vào một tin nhắn để chặn người gửi hoặc báo cáo. Vi phạm sẽ bị cấm chat."

# ------------------------------------------------------------------ text
## Whole words only, with their accents: unaccented spellings such as "lon",
## "cac" or "buoi" are everyday words (lon, các, buổi).
const SWEARS := {
	"đụ": 1, "địt": 1, "đéo": 1, "đếch": 1, "lồn": 1, "cặc": 1, "buồi": 1, "đĩ": 1, "điếm": 1,
	"đm": 1, "dm": 1, "đmm": 1, "dmm": 1, "đcm": 1, "dcm": 1, "đcmm": 1, "dcmm": 1, "đkm": 1, "dkm": 1,
	"vcl": 1, "vkl": 1, "vcc": 1, "vl": 1, "clm": 1, "cmm": 1, "cmn": 1, "cc": 1, "loz": 1, "lìn": 1,
	"đjt": 1, "djt": 1, "dit": 1, "đit": 1, "cak": 1, "kak": 1,
	"fuck": 1, "fucking": 1, "fck": 1, "shit": 1, "bitch": 1, "dick": 1, "pussy": 1, "cunt": 1,
}

static var _word_re: RegEx
static var _rep_re: RegEx
static var _ws_re: RegEx

static func _res() -> void:
	if _word_re:
		return
	_word_re = RegEx.create_from_string("[\\p{L}\\p{M}\\p{N}]+")
	_rep_re = RegEx.create_from_string("(.)\\1+")
	_ws_re = RegEx.create_from_string("\\s+")

static func _is_swear(w: String) -> bool:
	var lower := w.to_lower()
	if SWEARS.has(lower):
		return true
	# repeated letters folded, so "địttt" and "vclll" are caught too
	return SWEARS.has(_rep_re.sub(lower, "$1", true))

## Every swear word replaced by stars.
static func censor(text: String) -> String:
	_res()
	var out := ""
	var at := 0
	for m in _word_re.search_all(text):
		out += text.substr(at, m.get_start() - at)
		var w := m.get_string()
		out += "*".repeat(w.length()) if _is_swear(w) else w
		at = m.get_end()
	return out + text.substr(at)

## A message as it is sent: one line, trimmed, at most MAX_LEN characters,
## swear words starred. "" when nothing is left.
static func clean(raw: String) -> String:
	_res()
	var t := _ws_re.sub(raw, " ", true).strip_edges()
	# the rules count characters too; Godot strings are UTF-32, so no split emoji
	t = t.substr(0, MAX_LEN).strip_edges()
	return censor(t)

# ------------------------------------------------------------------ time
## RFC 3339 server timestamp → unix seconds (0 if unreadable).
static func unix(ts: String) -> float:
	if ts.length() < 19:
		return 0.0
	var base := Time.get_unix_time_from_datetime_string(ts.substr(0, 19))
	var frac := 0.0
	if ts.length() > 20 and ts[19] == ".":
		var digits := ts.substr(20).rstrip("Z")
		frac = ("0." + digits).to_float()
	return base + frac

## "14:05" for today, "18/11 14:05" otherwise, in the phone's time zone.
static func clock(ts: String) -> String:
	var u := unix(ts)
	if u <= 0.0:
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(int(u) + bias)
	var now := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system()) + bias)
	var hm := "%02d:%02d" % [d.hour, d.minute]
	if d.day == now.day and d.month == now.month and d.year == now.year:
		return hm
	return "%02d/%02d %s" % [d.day, d.month, hm]

# ------------------------------------------------------------- local prefs
static func rules_accepted() -> bool:
	return bool(Game.settings.get("chat_rules", false))

static func accept_rules() -> void:
	Game.settings["chat_rules"] = true
	Game.save_settings()

static func blocked() -> Array:
	var b = Game.settings.get("chat_blocked", [])
	return b if b is Array else []

static func block(uid: String) -> void:
	var b := blocked().duplicate()
	if not uid in b:
		b.append(uid)
	Game.settings["chat_blocked"] = b
	Game.save_settings()

static func unblock_all() -> void:
	Game.settings["chat_blocked"] = []
	Game.save_settings()

static func reported() -> Array:
	var r = Game.settings.get("chat_reported", [])
	return r if r is Array else []

## Seconds until this phone may send again (0 = now).
static func wait_left() -> float:
	var last := float(Game.settings.get("chat_last", 0.0))
	return maxf(0.0, last + COOLDOWN - Time.get_unix_time_from_system())

## Messages this player wants to see.
static func visible(msgs: Array) -> Array:
	var b := blocked()
	var r := reported()
	return msgs.filter(func(m): return not str(m.get("uid", "")) in b and not str(m.get("_id", "")) in r)

# ----------------------------------------------------------------- server
static func _row(m: Dictionary) -> Dictionary:
	# the sender's app censors too; again for old or modded ones
	m["text"] = censor(str(m.get("text", "")))
	m["name"] = str(m.get("name", "?")).substr(0, 24)
	return m

## Newest SHOWN messages, oldest first; null on error.
static func load_latest():
	var rows = await Cloud.run_query({
		"from": [{"collectionId": COLLECTION}],
		"orderBy": [{"field": {"fieldPath": "at"}, "direction": "DESCENDING"}],
		"limit": SHOWN,
	})
	if rows == null:
		return null
	var out := []
	for m in rows:
		out.push_front(_row(m))
	return out

## Messages after server time `after` (RFC 3339), oldest first; null on error.
static func load_after(after: String):
	var rows = await Cloud.run_query({
		"from": [{"collectionId": COLLECTION}],
		"where": {"fieldFilter": {"field": {"fieldPath": "at"}, "op": "GREATER_THAN", "value": {"timestampValue": after}}},
		"orderBy": [{"field": {"fieldPath": "at"}, "direction": "ASCENDING"}],
		"limit": SHOWN,
	})
	if rows == null:
		return null
	return rows.map(func(m): return _row(m))

static func _new_id() -> String:
	const AB := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var s := ""
	for i in 20:
		s += AB[randi() % AB.length()]
	return s

## Sends one message as the current hero. Returns "" on success, else a
## reason to show.
static func send(text: String) -> String:
	var t := clean(text)
	if t == "":
		return "Hãy nhập nội dung."
	var h := Game.hero
	if h.is_empty() or int(h.level) < MIN_LEVEL:
		return "Đạt cấp %d để nói chuyện trên Kênh Thế Giới." % MIN_LEVEL
	if wait_left() > 0.0:
		return "Đợi %d giây nữa để gửi tiếp." % ceili(wait_left())
	if not await Cloud._ensure_token():
		return "Không kết nối được máy chủ."
	var code: int = await Cloud.commit([
		{"path": "chatlast/" + Cloud.uid, "fields": {}, "server_time": ["at"]},
		{"path": "%s/%s" % [COLLECTION, _new_id()], "create": true, "server_time": ["at"],
			"fields": {"uid": Cloud.uid, "name": str(h.name).substr(0, 24), "sect": str(h.sect), "level": int(h.level), "text": t}},
	])
	if code == 200:
		Game.settings["chat_last"] = Time.get_unix_time_from_system()
		Game.save_settings()
		return ""
	if code == 0:
		return "Không kết nối được máy chủ."
	if code == 403:
		# phone clock off, another phone of this account, or muted
		Game.settings["chat_last"] = Time.get_unix_time_from_system()
		return "Gửi quá nhanh hoặc tài khoản đang bị cấm chat."
	return "Không gửi được (lỗi %d)." % code

static func delete_msg(id: String) -> bool:
	return await Cloud.delete_path("%s/%s" % [COLLECTION, id])

## Report: stored for review in the console, hidden on this phone at once.
static func report(m: Dictionary) -> void:
	var id := str(m.get("_id", ""))
	var r := reported().duplicate()
	if not id in r:
		r.append(id)
	Game.settings["chat_reported"] = r.slice(maxi(0, r.size() - 300))
	Game.save_settings()
	if not await Cloud._ensure_token():
		return
	await Cloud.commit([{"path": "chatreport/%s_%s" % [id, Cloud.uid], "server_time": ["at"],
		"fields": {"msg": id, "who": str(m.get("uid", "")), "name": str(m.get("name", "")), "text": str(m.get("text", "")), "by": Cloud.uid}}])

## Account deletion: removes every message this account sent.
static func delete_mine() -> void:
	for _round in 10:
		var rows = await Cloud.run_query({
			"from": [{"collectionId": COLLECTION}],
			"where": {"fieldFilter": {"field": {"fieldPath": "uid"}, "op": "EQUAL", "value": {"stringValue": Cloud.uid}}},
			"limit": 100,
		})
		if rows == null or rows.is_empty():
			return
		for m in rows:
			await delete_msg(str(m._id))
