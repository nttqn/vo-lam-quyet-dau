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

static func stars(h: Dictionary) -> int:
	var n := 0
	for k in h.get("stars", {}):
		n += int(h.stars[k])
	return n

static func fields(h: Dictionary) -> Dictionary:
	return {"name": str(h.name).substr(0, 24), "sect": str(h.sect), "level": int(h.level),
		"power": Hero.power(h), "tower": Tower.best(h), "stars": stars(h), "outfit": str(h.get("outfit", ""))}

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
	elif Game.slot >= 0 and not Game.hero.is_empty():
		var f := fields(Game.hero)
		_last[Game.slot] = f
		await Cloud.put_doc(COLLECTION, "_%d" % Game.slot, f)

## Fire-and-forget upload of this hero's row if it changed.
static func publish(h: Dictionary, slot: int) -> void:
	if not Cloud.enabled() or slot < 0 or h.is_empty() or hidden():
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
