class_name Funnel
extends RefCounted
## New-player funnel: where players get to and where they stop.
##
## There is no Firebase Analytics SDK for Godot, so each step is a counter
## document funnel/<step> {n}, bumped by one over Firestore REST
## (Cloud.bump). Each phone sends each step once (settings "funnel_sent"), so
## a second hero or a re-made one does not count a new player twice. Steps
## wait in "funnel_wait" while offline and go with the next save.
## Purchases (p_<sku>) and refused purchases (iap_bad_<why>) are plain events,
## counted every time. Nothing personal is sent: no uid field, no name.
## Read the numbers with: node tools/funnel_report.mjs
##
## Rules in firestore.rules (match /funnel/{id}) allow only +1 on "n".

const COLLECTION := "funnel"
const LEVELS := [2, 3, 5, 8, 10, 15, 20, 25, 30, 35, 40, 50, 60]
const STAGES := [0, 2, 5]            # per region: first duel, 3rd, boss
const DAYS := [1, 2, 3, 7, 14, 30]

static var _busy := false

## Phones only: desktop runs are tests, not players.
static func _on() -> bool:
	return OS.get_name() in ["Android", "iOS"] or "--funneltest" in OS.get_cmdline_user_args()

## Steps hero h has reached (sent or not).
static func reached(h: Dictionary) -> Array:
	var out := ["f_hero"]
	var fights := int(h.get("fights", 0))
	if fights >= 1: out.append("f_fight1")
	if int(h.get("wins", 0)) >= 1: out.append("f_win1")
	if fights >= 10: out.append("f_fight10")
	if fights >= 50: out.append("f_fight50")
	if fights >= 200: out.append("f_fight200")
	for lv in LEVELS:
		if int(h.level) >= lv:
			out.append("f_lv%d" % lv)
	var stars: Dictionary = h.get("stars", {})
	for r in Journey.REGIONS.size():
		for s in STAGES:
			if stars.has(Journey.stage_id(r, s)):
				out.append("f_r%ds%d" % [r + 1, s + 1])
	var tb := Tower.best(h)
	for f in [1, 10, 30]:
		if tb >= f: out.append("f_tower%d" % f)
	if int(h.get("arena_best", 0)) >= 5: out.append("f_arena5")
	for i in Dungeon.LIST.size():
		if Dungeon.best(h, i) >= 0:
			out.append("f_dungeon1")
			break
	var ac: Dictionary = h.get("ach_c", {})
	if int(ac.get("duels", 0)) >= 1: out.append("f_duel1")
	if Achieve.max_plus(h) >= 7: out.append("f_forge7")
	if not Insight.learned(h).is_empty(): out.append("f_insight")
	if not Array(h.get("outfits", [])).is_empty(): out.append("f_outfit")
	if int(h.get("paid", 0)) > 0: out.append("f_paid")
	var days := days_since(float(h.get("created", 0)))
	for d in DAYS:
		if days >= d:
			out.append("f_day%d" % d)
	return out

## Whole calendar days (local time) from unix time t to now.
static func days_since(t: float) -> int:
	if t <= 0.0:
		return -1
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := Time.get_unix_time_from_system()
	return int(floor((now + bias) / 86400.0)) - int(floor((t + bias) / 86400.0))

## Called on every save: queues new steps of this hero and sends them.
static func track(h: Dictionary) -> void:
	if h.is_empty() or not _on():
		return
	var sent: Array = Game.settings.get("funnel_sent", [])
	var wait: Array = Game.settings.get("funnel_wait", [])
	var grew := false
	for s in reached(h):
		if not s in sent and not s in wait:
			wait.append(s)
			grew = true
	if grew:
		Game.settings["funnel_wait"] = wait
		Game.save_settings()
	flush()

## Device steps (first launch).
static func device(step: String) -> void:
	if not _on():
		return
	var sent: Array = Game.settings.get("funnel_sent", [])
	var wait: Array = Game.settings.get("funnel_wait", [])
	if step in sent or step in wait:
		return
	wait.append(step)
	Game.settings["funnel_wait"] = wait
	Game.save_settings()
	flush()

## One-off event counted every time (purchases). Fire and forget.
static func event(name: String) -> void:
	if not _on() or not Cloud.enabled():
		return
	Cloud.bump(COLLECTION, [_clean(name)])

static func _clean(s: String) -> String:
	var out := ""
	for c in s.to_lower():
		out += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_" else "_"
	return out.substr(0, 40)

## Sends whatever waits, at most 20 per commit.
static func flush() -> void:
	if _busy or not Cloud.enabled():
		return
	var wait: Array = Game.settings.get("funnel_wait", [])
	if wait.is_empty():
		return
	_busy = true
	var batch := wait.slice(0, 20)
	var code: int = await Cloud.bump(COLLECTION, batch)
	_busy = false
	if code != 200:
		return
	var sent: Array = Game.settings.get("funnel_sent", [])
	var still: Array = Game.settings.get("funnel_wait", [])
	for s in batch:
		if not s in sent:
			sent.append(s)
		still.erase(s)
	Game.settings["funnel_sent"] = sent
	Game.settings["funnel_wait"] = still
	Game.save_settings()
	if not still.is_empty():
		flush()
