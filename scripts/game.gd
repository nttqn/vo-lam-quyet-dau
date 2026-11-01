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

# ------------------------------------------------------------- navigation
func goto(node: Node) -> void:
	var root := get_tree().root.get_node("Main")
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = node
	Engine.time_scale = 1.0
	root.add_child(node)

# ------------------------------------------------------------- audio
const SFX_NAMES := ["hit", "hit_heavy", "slash", "swing", "block", "gong", "click", "ko", "boom", "throw", "skill", "heal", "land", "win", "lose", "start", "counter", "coin", "levelup", "music_menu", "music_fight"]

func _load_audio() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for n in SFX_NAMES:
		var path := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = load(path)

func sfx(name: String, pitch_var := 0.08) -> void:
	var s: AudioStream = _sfx.get(name)
	if s == null or float(settings.sfx) <= 0.0:
		return
	var p := _players[_rr]
	_rr = (_rr + 1) % _players.size()
	p.stream = s
	p.volume_db = linear_to_db(float(settings.sfx))
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

func music(name: String) -> void:
	if name == _music_name and _music_player.playing:
		return
	_music_name = name
	var s: AudioStream = _sfx.get("music_" + name)
	if s == null:
		_music_player.stop()
		return
	_music_player.stream = s
	_music_player.volume_db = linear_to_db(maxf(0.0001, float(settings.music)))
	if float(settings.music) > 0.0:
		_music_player.play()

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

func delete_slot(i: int) -> void:
	var p := ProjectSettings.globalize_path(SAVE_PATH % i)
	if FileAccess.file_exists(SAVE_PATH % i):
		DirAccess.remove_absolute(p)

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
