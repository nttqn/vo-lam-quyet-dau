extends Node
## Renders a picture of every sect skill for the Võ Công screen: the sect's
## fighter walks up to an idle opponent, uses the skill, and the frame at the
## strike is cropped around the fighter.
##   godot --path . --resolution 1280x720 -- --skillshots [--sect=thieu_lam] [--only=2]
## Output: res://assets/ui/skills/<sect>_<i>.png (480x360)

const OUT := "res://assets/ui/skills/"
const THEME := {"thieu_lam": "temple", "vo_dang": "peak", "nga_mi": "river", "cai_bang": "desert", "duong_mon": "bamboo"}
const FOE := {"thieu_lam": "duong_mon", "vo_dang": "cai_bang", "nga_mi": "thieu_lam", "cai_bang": "vo_dang", "duong_mon": "nga_mi"}
const GO := 200

var jobs: Array = []
var fs: FightScene
var target := 0
var cur: Array
var ahead := 0.5     # crop centre, metres in front of the fighter

func _ready() -> void:
	var only_sect := ""
	var only := -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sect="): only_sect = a.substr(7)
		if a.begins_with("--only="): only = int(a.substr(7))
	for s in Sects.all():
		if only_sect != "" and s.id != only_sect:
			continue
		for i in s.skills.size():
			if only < 0 or only == i:
				jobs.append([s.id, i])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_next.call_deferred()

func _next() -> void:
	if jobs.is_empty():
		get_tree().quit()
		return
	cur = jobs.pop_front()
	var sid: String = cur[0]
	var m: Dictionary = Sects.get_sect(sid).skills[cur[1]]
	var p := Npc.side(sid, 30, "Minh Họa", 0.5, "", false, 5)
	p.look = Sects.get_sect(sid).look.duplicate()
	p.skills = [m]
	var e := Npc.side(FOE[sid], 30, "Đối Thủ", 0.5, "", false, 9)
	e.look = Sects.get_sect(FOE[sid]).look.duplicate()
	fs = FightScene.new({"p": p, "e": e, "theme": THEME[sid], "seed": 4, "training": true})
	var script := {}
	var walk := 0 if m.get("kind", "") in ["proj", "rain", "buff", "heal", "counter"] else 48
	for f in range(GO - walk, GO):
		script[f] = {"mx": 1}
	script[GO] = {"btn": "s1"}
	fs._script = script
	var kind: String = m.get("kind", "strike")
	ahead = 1.3 if kind in ["proj", "rain"] else 0.5
	var t := int(m.st) + 2
	match kind:
		"strike", "rush", "blink":
			t = int(m.st) + int(int(m.act) * (0.35 if int(m.get("hits", 1)) > 1 else 0.2)) + 1
		"proj", "rain":
			t = int(m.st) + 6
		"buff", "heal", "counter":
			t = int(m.st) + int(m.act) + 4
		"leap":
			t = int(m.st) + int(m.act) - 2
	target = GO + 1 + t
	Game.goto(fs)

func _process(_d: float) -> void:
	if fs == null or not is_instance_valid(fs) or fs.sim == null:
		return
	fs.sim.f[0].en = Fighter.EN_MAX
	# picture only: no HUD, touch pad, banners or floating numbers
	for n in fs.find_children("*", "CanvasLayer", true, false):
		(n as CanvasLayer).visible = false
	for n in fs.find_children("*", "Label3D", true, false):
		(n as Label3D).visible = false
	if fs._frames < target:
		return
	var cam := get_viewport().get_camera_3d()
	var f0: Fighter = fs.sim.f[0]
	var c := cam.unproject_position(Vector3(f0.x + f0.facing * ahead, f0.y + 1.0, 0))
	var img := get_viewport().get_texture().get_image()
	var h := 400.0
	var w := h * 4.0 / 3.0
	var r := Rect2i(int(clampf(c.x - w * 0.5, 0, img.get_width() - w)), int(clampf(c.y - h * 0.55, 0, img.get_height() - h)), int(w), int(h))
	var out := img.get_region(r)
	out.resize(480, 360, Image.INTERPOLATE_LANCZOS)
	out.adjust_bcs(0.86, 1.1, 1.05)   # the in-game shading overlays are hidden here
	var path := OUT + "%s_%d.png" % [cur[0], cur[1]]
	out.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, "  state=", f0.state, " sf=", f0.sf, " move=", f0.move_key)
	fs = null
	_next.call_deferred()
