extends Node3D
## Renders a line-up of fighters in various poses and saves a screenshot.

var shot := "user://pose.png"
var frames := 0

func _ready() -> void:
	var theme := "temple"
	var mode := "styles"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
		if a.begins_with("--theme="): theme = a.substr(8)
		if a.begins_with("--mode="): mode = a.substr(7)
	add_child(Arena.new(theme))
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	var looks := [
		{"robe": Color(0.9, 0.55, 0.15), "trim": Color(0.6, 0.15, 0.1), "pants": Color(0.75, 0.45, 0.15), "head_style": "bald", "weapon": "staff", "beads": true, "sash": Color(0.6, 0.15, 0.1), "_s": "staff"},
		{"robe": Color(0.35, 0.45, 0.6), "trim": Color(0.92, 0.92, 0.95), "pants": Color(0.2, 0.22, 0.3), "head_style": "bun", "weapon": "sword", "sash": Color(0.15, 0.15, 0.2), "_s": "sword"},
		{"robe": Color(0.95, 0.93, 0.95), "trim": Color(0.85, 0.4, 0.55), "pants": Color(0.85, 0.75, 0.82), "head_style": "long", "weapon": "dual", "female": true, "bulk": 0.88, "height": 0.95, "sash": Color(0.85, 0.35, 0.5), "_s": "dual"},
		{"robe": Color(0.45, 0.4, 0.25), "trim": Color(0.3, 0.45, 0.25), "pants": Color(0.35, 0.3, 0.22), "head_style": "headband", "weapon": "none", "bulk": 1.15, "sash": Color(0.55, 0.35, 0.15), "bracers": true, "_s": "palm"},
		{"robe": Color(0.22, 0.16, 0.28), "trim": Color(0.55, 0.15, 0.2), "pants": Color(0.12, 0.1, 0.15), "head_style": "hood", "weapon": "daggers", "sash": Color(0.55, 0.15, 0.2), "_s": "dagger"},
	]
	var names := ["stance", "jab", "fkick", "sweep", "slash_hi", "thrust"]
	if mode == "styles":
		for i in looks.size():
			var b := Body.new(looks[i])
			add_child(b)
			b.position = Vector3(-4.4 + i * 2.2, 0, 0)
			b.rotation.y = -0.5
			b.apply_pose(Poses.stance(looks[i]._s))
		cam.position = Vector3(0, 1.4, 8.5)
		cam.look_at(Vector3(0, 1.0, 0))
	else:
		var lk: Dictionary = looks[int(mode.substr(4))] if mode.begins_with("look") else looks[0]
		var keys := ["stance", "jab", "cross", "fkick", "skick", "sweep", "palm", "slash_hi", "thrust", "rising", "staff_over", "toss"]
		var keyarg := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--keys="): keys = a.substr(7).split(",")
		for i in keys.size():
			var b := Body.new(lk)
			add_child(b)
			b.position = Vector3(-5.5 + i * 2.2, 0, 0)
			b.rotation.y = -0.25
			var k: String = keys[i]
			var p: Dictionary
			match k:
				"stance": p = Poses.stance(lk._s)
				"crouch": p = Poses.crouch(lk._s)
				"block": p = Poses.block(lk._s, false)
				"hurt": p = Poses.hurt(lk._s, true)
				"lying": p = Poses.lying()
				"jump": p = Poses.jump(lk._s)
				"victory": p = Poses.victory(lk._s)
				"dodge": p = Poses.dodge(lk._s)
				"air": p = Poses.airborne_hurt()
				_: p = Poses.key(k, lk._s)
			b.apply_pose(p)
			var l := Label3D.new()
			l.text = k
			l.position = b.position + Vector3(0, 2.2, 0)
			l.font_size = 48
			add_child(l)
		cam.position = Vector3(0, 1.3, 9.5)
		cam.look_at(Vector3(0, 0.9, 0))

func _process(_d: float) -> void:
	frames += 1
	if frames == 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot)
		print("saved ", ProjectSettings.globalize_path(shot))
		get_tree().quit()
