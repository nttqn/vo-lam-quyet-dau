extends Node3D
## Adds one Avatar per sect (and the arena) step by step, printing memory after each.
##   godot --path . -- --memmodels
const SECTS := ["thieu_lam", "vo_dang", "nga_mi", "cai_bang", "duong_mon"]
func _ready() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 6)
	add_child(cam)
	await _wait()
	_stat("empty")
	add_child(Arena.new("temple", 1))
	await _wait()
	_stat("arena")
	var x := -4.0
	for s in SECTS:
		var b := Avatar.new(Sects.get_sect(s).look)
		b.position.x = x
		x += 2.0
		add_child(b)
		await _wait()
		_stat("+ " + s)
	get_tree().quit()
func _wait() -> void:
	for k in 10:
		await get_tree().process_frame
func _stat(tag: String) -> void:
	print("%-14s mem=%.1fMB tex=%.1fMB vram=%.1fMB" % [tag, OS.get_static_memory_usage() / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
