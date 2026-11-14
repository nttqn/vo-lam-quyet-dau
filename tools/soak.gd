extends Node
## Soak test: back-to-back autoplay fights, logging memory/object counts to
## catch leaks or growth that would crash a phone after a while.
##   godot --path . --fixed-fps 60 --disable-vsync -- --soak [--n=12]

const SECTS := ["thieu_lam", "vo_dang", "nga_mi", "cai_bang", "duong_mon"]
var n := 12
var i := 0
var fs: FightScene
var frames := 0
var _last_tm := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
	_next.call_deferred()

func _stat(tag: String) -> void:
	print("%s mem=%.1fMB objs=%d nodes=%d orphans=%d vram=%.1fMB tex=%.1fMB" % [tag,
		OS.get_static_memory_usage() / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])

func _next() -> void:
	if i >= n:
		_stat("END")
		get_tree().quit()
		return
	var ps: String = SECTS[i % 5]
	var es: String = SECTS[(i * 3 + 1) % 5]
	var p := Npc.side(ps, 30, "Soak", 0.8, "", false, 5)
	p.skills = [Sects.get_sect(ps).skills[0], Sects.get_sect(ps).skills[2], Sects.get_sect(ps).skills[3], Sects.get_sect(ps).skills[5]]
	var e := Npc.side(es, 30, "Đối Thủ", 0.8, "bandit", true, 9)
	fs = FightScene.new({"p": p, "e": e, "theme": ["temple", "night", "bamboo"][i % 3], "autoplay": true, "seed": i + 1})
	Game.goto(fs)
	frames = 0
	i += 1

func _process(_d: float) -> void:
	if fs == null or not is_instance_valid(fs):
		return
	frames += 1
	var tm := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	if tm > _last_tm + 8 * 1048576:
		var evs := []
		for e in fs.sim.events: evs.append(str(e.get("t", "")) + ":" + str(e.get("name", "")))
		_stat("  JUMP fight %d frame %d events=%s" % [i, frames, evs])
	_last_tm = tm
	if frames % 1200 == 0:
		_stat("  fight %d frame %d" % [i, frames])
	if (fs._done and fs._end_t > 2.0) or frames > 60 * 60 * 3:
		_stat("fight %d done frames=%d" % [i, frames])
		fs = null
		_next.call_deferred()

