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

## Fire-and-forget upload of this hero's row if it changed.
static func publish(h: Dictionary, slot: int) -> void:
	if not Cloud.enabled() or slot < 0 or h.is_empty():
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
