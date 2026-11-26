class_name Replay
extends RefCounted
## Xem lại trận (1.5.0). The fight sim is deterministic given its seed and both
## fighters' inputs, so a replay is the fight's starting cfg plus the two input
## streams, stored only on the frames where an input changed:
##   {ver, cfg, p: [[frame, mx, up, down, btn], ...], e: [...], frames,
##    winner, hp: [p_hp, e_hp], meta: {...}}
## FightScene records every recordable fight; the last one stays in memory
## (Replay.last) for the result screen, and the player can keep up to KEEP of
## them in user://replays/ (var_to_str: keeps int / float / Color exactly,
## JSON would turn ints into floats).

const DIR := "user://replays"
const INDEX := "user://replays/index.json"
const KEEP := 12

static var last := {}

# ------------------------------------------------------------- recording
## Appends side i's input for `frame` when it differs from the last one.
static func push(stream: Array, frame: int, inp: Dictionary) -> void:
	var mx := int(inp.get("mx", 0))
	var up := 1 if inp.get("up", false) else 0
	var dn := 1 if inp.get("down", false) else 0
	var btn := str(inp.get("btn", ""))
	if not stream.is_empty():
		var l: Array = stream[stream.size() - 1]
		if int(l[1]) == mx and int(l[2]) == up and int(l[3]) == dn and str(l[4]) == btn:
			return
	stream.append([frame, mx, up, dn, btn])

## Playback cursor over one stream: input(frame) for increasing frames.
class Cursor:
	var s: Array
	var i := 0
	var cur := {"mx": 0, "up": false, "down": false, "btn": ""}
	func _init(stream: Array) -> void:
		s = stream
	func input(frame: int) -> Dictionary:
		while i < s.size() and int(s[i][0]) <= frame:
			var e: Array = s[i]
			cur = {"mx": int(e[1]), "up": int(e[2]) == 1, "down": int(e[3]) == 1, "btn": str(e[4])}
			i += 1
		# run-length: the input holds until the next change (a button released
		# on the next frame is its own change, so it never repeats by mistake)
		return cur.duplicate()

## What the list shows for a fight: mode, names, sects, outcome.
static func meta_for(cfg: Dictionary, mode: String, won: bool, seconds: float) -> Dictionary:
	return {"mode": mode, "p": str(cfg.p.get("name", "")), "e": str(cfg.e.get("name", "")),
		"ps": str(cfg.p.get("sect", "")), "es": str(cfg.e.get("sect", "")),
		"pl": int(cfg.p.get("level", 1)), "el": int(cfg.e.get("level", 1)),
		"title": str(cfg.e.get("title", "")), "won": won, "secs": int(seconds),
		"t": int(Time.get_unix_time_from_system())}

static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

## Mode label shown in lists.
static func mode_name(mode: String) -> String:
	match mode:
		"stage": return "Hành Tẩu"
		"nm": return "Ác Mộng"
		"duel": return "Tỉ Võ"
		"spar": return "Đấu thử"
		"tower": return "Tháp Thí Luyện"
		"arena": return "Lôi Đài"
		"dungeon": return "Phó Bản"
		"wboss": return "Boss Thế Giới"
		"kyngo": return "Kỳ Ngộ"
	return "Trận đấu"

# ------------------------------------------------------------- saved fights
static func list() -> Array:
	var f := FileAccess.open(INDEX, FileAccess.READ)
	if f == null:
		return []
	var d = JSON.parse_string(f.get_as_text())
	if not d is Array:
		return []
	var out := []
	for m in d:
		if m is Dictionary and FileAccess.file_exists(_path(str(m.get("id", "")))):
			out.append(m)
	return out

static func count() -> int:
	return list().size()

static func _path(id: String) -> String:
	return "%s/%s.rp" % [DIR, id.validate_filename()]

static func _write_index(rows: Array) -> void:
	var f := FileAccess.open(INDEX, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(rows))

## Keeps a replay; false when the shelf is full (KEEP) or the disk refused.
static func save(rp: Dictionary) -> bool:
	if rp.is_empty():
		return false
	var rows := list()
	if rows.size() >= KEEP:
		return false
	DirAccess.make_dir_recursive_absolute(DIR)
	var id := "%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
	var f := FileAccess.open(_path(id), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(var_to_str(rp))
	f.close()
	var m: Dictionary = rp.get("meta", {}).duplicate()
	m["id"] = id
	m["ver"] = str(rp.get("ver", ""))
	rows.push_front(m)
	_write_index(rows)
	rp["saved_id"] = id
	return true

static func load_one(id: String) -> Dictionary:
	var f := FileAccess.open(_path(id), FileAccess.READ)
	if f == null:
		return {}
	var v = str_to_var(f.get_as_text())
	if not v is Dictionary or not (v.get("cfg") is Dictionary) or not (v.get("p") is Array):
		return {}
	return v

static func delete(id: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(id)))
	var rows := list().filter(func(m): return str(m.get("id", "")) != id)
	_write_index(rows)
