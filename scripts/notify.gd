class_name Notify
extends RefCounted
## Local reminders (1.3.0, Android only: VLNotify in the VLGoogleAuth AAR).
## When the game goes to the background it schedules up to three reminders at
## 19:00 local time (tomorrow, +3 days, +7 days) and cancels them all when it
## comes back, so a player who opens the game daily never sees one. Day-1
## return was 11% and day-7 0.4% in the funnel. Off with settings["notify"].
## Silent no-op on desktop and iOS.

const _PLUGIN := "VLNotify"
const HOUR := 19
const IDS := [101, 103, 107]
static var _p: Object = null
static var _looked := false

static func _plugin() -> Object:
	if not _looked:
		_looked = true
		if Engine.has_singleton(_PLUGIN):
			_p = Engine.get_singleton(_PLUGIN)
	return _p

static func enabled() -> bool:
	return bool(Game.settings.get("notify", true))

static func allowed() -> bool:
	var p := _plugin()
	return p != null and bool(p.allowed())

## Android 13+ permission prompt, once per phone (after the first won duel).
static func ask_once() -> void:
	var p := _plugin()
	if p == null or Game.settings.get("notify_asked", false) or not enabled():
		return
	Game.settings["notify_asked"] = true
	Game.save_settings()
	p.requestPermission()

static func ask() -> void:
	var p := _plugin()
	if p:
		p.requestPermission()

static func on_foreground() -> void:
	var p := _plugin()
	if p:
		p.cancelAll()

static func on_background() -> void:
	var p := _plugin()
	if p == null:
		return
	p.cancelAll()
	if not enabled() or Game.hero.is_empty():
		return
	for i in IDS.size():
		var m := message(Game.hero, i)
		if not m.is_empty():
			p.schedule(IDS[i], seconds_to(HOUR, [1, 3, 7][i]), m.title, m.body)

## Seconds from now until `hour`:00 local time, `days` days ahead.
static func seconds_to(hour: int, days: int) -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := int(Time.get_unix_time_from_system())
	var local := now + bias
	var day_start := local - posmod(local, 86400)
	return day_start + days * 86400 + hour * 3600 - local

## Reminder i (0 = tomorrow, 1 = three days, 2 = a week) for hero h.
static func message(h: Dictionary, i: int) -> Dictionary:
	var name := str(h.get("name", "Hiệp khách"))
	if i == 0:
		if WBoss.unlocked(h):
			var tomorrow := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) + 86400 + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
			var b := WBoss.today_boss(tomorrow)
			return {"title": "Boss Thế Giới: %s" % b.name,
				"body": "%s đã xuất hiện! Cùng cả giang hồ dồn sát thương, chia thưởng theo hạng. Đừng quên điểm danh nhận quà." % b.name}
		var nx := next_stage(h)
		if not nx.is_empty():
			return {"title": "%s đang chờ %s" % [nx.foe, name],
				"body": "Trận kế ở %s: %s — %s. Thắng để lên cấp và nhận trang bị mới!" % [nx.region, nx.foe, nx.title]}
		return {"title": "Quà điểm danh đang chờ", "body": "%s, quà điểm danh hôm nay đã sẵn sàng." % name}
	if i == 1:
		return {"title": "Giang hồ nhắc tên %s" % name,
			"body": "Đã ba ngày vắng bóng. Quà điểm danh, Lôi Đài và Tháp Thí Luyện vẫn đang chờ."}
	return {"title": "Võ lâm chưa có hồi kết",
		"body": "%s ơi, cao thủ khắp nơi đã mạnh lên nhiều. Quay lại luyện công kẻo tụt hạng!" % name}

## The next story duel the hero has not won ({} when the story is done).
static func next_stage(h: Dictionary) -> Dictionary:
	for r in Journey.REGIONS.size():
		for s in 6:
			if not Dictionary(h.get("stars", {})).has(Journey.stage_id(r, s)):
				var reg: Dictionary = Journey.REGIONS[r]
				return {"region": reg.name, "foe": reg.foes[s][0], "title": reg.foes[s][1]}
	return {}
