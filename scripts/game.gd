extends Node
## Global game state (autoload "Game"): save slots, hero, navigation, audio.

const SAVE_PATH := "user://save_%d.json"
const SETTINGS_PATH := "user://settings.json"
const SLOTS := 3

var hero: Dictionary = {}
var slot := -1
var autoplay := false      # test hook: the hero fights by itself
var settings := {"sfx": 0.8, "music": 0.55, "vibrate": true}
var _current: Node
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_name := ""
var _rr := 0

func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	_load_settings()
	_load_audio()
	if Diag.on("memlog"):
		var t := Timer.new()
		t.wait_time = 5.0
		t.autostart = true
		t.timeout.connect(func(): print("MEM godot_static=%.1fMB objs=%d tex=%.1fMB fps=%d" % [OS.get_static_memory_usage() / 1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, Engine.get_frames_per_second()]))
		add_child(t)

# ------------------------------------------------------------- navigation
func goto(node: Node) -> void:
	var root := get_tree().root.get_node("Main")
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = node
	Engine.time_scale = 1.0
	root.add_child(node)

# ------------------------------------------------------------- back button
## Android back arrives two ways in Godot 4.7: with the classic back key the
## render view swallows KEYCODE_BACK and it becomes an InputEventKey KEY_BACK
## (no WM_GO_BACK_REQUEST at all); with predictive back (Android 16+) it comes
## as WM_GO_BACK_REQUEST. Handle both here (plus Esc on desktop) and route to
## the open modal or the current screen's back(). One physical press can reach
## us twice (key + WM, or a repeated key on some phones), so any back within
## 400 ms of the last one is dropped.
var _back_ms := -10000

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back("wm")

func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and (k.keycode == KEY_BACK or k.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_go_back("key")

func _go_back(src: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _back_ms < 400:
		return
	_back_ms = now
	var modals := get_tree().get_nodes_in_group("modal")
	modals.reverse()   # newest (last in tree order) first
	for m in modals:
		if m.is_inside_tree() and not m.is_queued_for_deletion() and (m as CanvasItem).is_visible_in_tree():
			m.queue_free()
			return
	if _current and is_instance_valid(_current) and _current.has_method("back"):
		_current.back()

# ------------------------------------------------------------- audio
## Single sounds: synthesised UI / music (tools/gen_audio.gd) and a few fight
## sounds from real recordings (tools/sfx/build.mjs).
const SFX_NAMES := ["gong", "click", "ko", "boom", "skill", "heal", "win", "lose", "start", "counter", "coin", "levelup", "wall", "music_menu", "music_fight"]
## Recorded fight sounds that come as variants <name>_1.._n; sfx(name) picks one at random.
const SFX_VARIANTS := ["swing_blade", "swing_light", "swing_staff", "swing_body", "hit_slash", "hit_blunt",
	"hit_punch", "hit_kick", "hit_palm", "hit_heavy", "block_metal", "block_wood", "block_body", "throw", "land",
	"hurt_m", "hurtbig_m", "ko_m", "kiai_m", "hurt_f", "hurtbig_f", "ko_f", "kiai_f"]

func _load_audio() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for n in SFX_NAMES:
		var path := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = [load(path)]
	for n in SFX_VARIANTS:
		var list := []
		for i in range(1, 13):
			var path := "res://assets/audio/%s_%d.wav" % [n, i]
			if not ResourceLoader.exists(path):
				break
			list.append(load(path))
		if not list.is_empty():
			_sfx[n] = list

func has_sfx(name: String) -> bool:
	return _sfx.has(name)

## vol: linear gain on top of the sound setting.
func sfx(name: String, pitch_var := 0.08, vol := 1.0) -> void:
	var list: Array = _sfx.get(name, [])
	if list.is_empty() and name != "":
		push_warning("sfx missing: " + name)
	if list.is_empty() or float(settings.sfx) <= 0.0:
		return
	var p := _players[_rr]
	_rr = (_rr + 1) % _players.size()
	p.stream = list[randi() % list.size()]
	p.volume_db = linear_to_db(float(settings.sfx) * vol)
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

func music(name: String) -> void:
	if name == _music_name and _music_player.playing:
		return
	_music_name = name
	var s: AudioStream = _sfx.get("music_" + name, [null])[0]
	if s == null:
		_music_player.stop()
		return
	_music_player.stream = s
	_music_player.volume_db = linear_to_db(maxf(0.0001, float(settings.music)))
	if float(settings.music) > 0.0:
		_music_player.play()

## Rewarded ads take over the screen: stop the music meanwhile.
func music_pause(on: bool) -> void:
	_music_player.stream_paused = on

func apply_volume() -> void:
	_music_player.volume_db = linear_to_db(maxf(0.0001, float(settings.music)))
	if float(settings.music) <= 0.0:
		_music_player.stop()
	elif not _music_player.playing and _music_name != "":
		var n := _music_name
		_music_name = ""
		music(n)

func vibrate(ms: int) -> void:
	if settings.vibrate and OS.get_name() == "Android":
		Input.vibrate_handheld(ms)

# ------------------------------------------------------------- saving
func _load_settings() -> void:
	var d = _read_json(SETTINGS_PATH)
	if d is Dictionary:
		for k in d:
			settings[k] = d[k]

func save_settings() -> void:
	_write_json(SETTINGS_PATH, settings)

func slot_info(i: int) -> Dictionary:
	var d = _read_json(SAVE_PATH % i)
	return d if d is Dictionary else {}

func load_slot(i: int) -> bool:
	var d := slot_info(i)
	if d.is_empty():
		return false
	slot = i
	hero = Hero.migrate(d)
	return true

func save() -> void:
	if slot < 0 or hero.is_empty():
		return
	hero["saved_at"] = Time.get_unix_time_from_system()
	_write_json(SAVE_PATH % slot, hero)
	Cloud.queue_upload(slot)
	Ranks.publish(hero, slot)

func delete_slot(i: int) -> void:
	park_slot(i)
	Cloud.delete_slot(i)
	Ranks.remove(i)

## Cloud pull: replace a slot's file with data from the server.
func write_slot(i: int, data: Dictionary) -> void:
	_write_json(SAVE_PATH % i, data)

## Keep the previous copy of a slot as save_N.bak.json before it is replaced or
## deleted, so a bad sync or a mistaken delete can be recovered by hand.
func park_slot(i: int) -> void:
	var p := SAVE_PATH % i
	if FileAccess.file_exists(p):
		var bak := p.replace(".json", ".bak.json")
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
		DirAccess.rename_absolute(ProjectSettings.globalize_path(p), ProjectSettings.globalize_path(bak))

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())

func _write_json(path: String, data) -> void:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
