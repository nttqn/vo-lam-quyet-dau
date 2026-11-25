class_name Ranks
extends RefCounted
## Bảng xếp hạng: one Firestore doc per hero, rank/{uid}_{slot}, with the
## fields each board sorts by. Published (only when something changed) from
## Game.save; removed with the slot / the account.

const COLLECTION := "rank"
const BOARDS := [
	["power", "Lực Chiến"],
	["level", "Cấp Độ"],
	["tower", "Tháp Thí Luyện"],
	["stars", "Giang Hồ"],
]

static var _last := {}   # slot -> fields last sent

## Heroes below this level are not listed (fresh throwaway heroes were most
## of the rank writes and of the rows people scrolled past).
const MIN_LEVEL := 2

## Giang Hồ stars: story + Ác Mộng.
static func stars(h: Dictionary) -> int:
	var n := 0
	for k in h.get("stars", {}):
		n += int(h.stars[k])
	for k in h.get("nstars", {}):
		n += int(h.nstars[k])
	return n

static func fields(h: Dictionary) -> Dictionary:
	return {"name": str(h.name).substr(0, 24), "sect": str(h.sect), "level": int(h.level),
		"power": Hero.power(h), "tower": Tower.best(h), "stars": stars(h), "outfit": str(h.get("outfit", "")),
		"title": Titles.worn(h), "lang": L.lang}

## Power and level both within reach (Build.max_power, Build.level_ok): listed
## on the boards and in Tỉ Võ. Here, not in Build, because stars() needs Game.
static func honest(h: Dictionary) -> bool:
	var lv := int(h.get("level", 1))
	return Hero.power(h) <= Build.max_power(lv) and Build.level_ok(lv, stars(h), Tower.best(h))

static func listed(h: Dictionary) -> bool:
	return not h.is_empty() and int(h.get("level", 1)) >= MIN_LEVEL and honest(h) and not Ban.active()

static func value(h: Dictionary, board: String) -> int:
	return int(fields(h)[board])

## "Ẩn khỏi bảng xếp hạng": nothing is published for any hero on this device
## while it is on: no rank rows, and no Tỉ Võ shadow (Duel.publish), so the
## player is off the weekly Tỉ Võ board and nobody gets them as a rival.
static func hidden() -> bool:
	return bool(Game.settings.get("rank_hidden", false))

## Turning it on deletes every slot's row and this season's Tỉ Võ shadow;
## turning it off republishes the current hero's row (other heroes reappear
## when next saved, the shadow on the next Tỉ Võ visit or duel).
static func set_hidden(on: bool) -> void:
	Game.settings["rank_hidden"] = on
	Game.save_settings()
	_last.clear()
	if not Cloud.enabled():
		return
	if on:
		for i in Game.SLOTS:
			await Cloud.delete_doc(COLLECTION, "_%d" % i)
		await Cloud.delete_doc(Duel.collection(), "")
		for i in Game.SLOTS:
			await Cloud.delete_doc(WBoss.collection(), "_%d" % i)
	elif Game.slot >= 0 and listed(Game.hero):
		var f := fields(Game.hero)
		_last[Game.slot] = f
		await Cloud.put_doc(COLLECTION, "_%d" % Game.slot, f)

## Fire-and-forget upload of this hero's row if it changed.
static func publish(h: Dictionary, slot: int) -> void:
	if not Cloud.enabled() or slot < 0 or hidden():
		return
	if not listed(h):
		# an edited save (honest) takes its old row down once; the rules
		# would refuse every update, leaving the stale row up for good
		if int(h.get("level", 1)) >= MIN_LEVEL and not honest(h) and not _last.get(slot, {}).has("_gone"):
			_last[slot] = {"_gone": true}
			Cloud.delete_doc(COLLECTION, "_%d" % slot)
		return
	var f := fields(h)
	if _last.get(slot, {}) == f:
		return
	_last[slot] = f
	Cloud.put_doc(COLLECTION, "_%d" % slot, f)

static func remove(slot: int) -> void:
	_last.erase(slot)
	if Cloud.enabled():
		Cloud.delete_doc(COLLECTION, "_%d" % slot)
