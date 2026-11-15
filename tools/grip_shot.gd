extends SceneTree
## Close-up of each weapon sect's hands holding the weapon in its idle stance.
##   godot --path . --resolution 1200x800 --script res://tools/grip_shot.gd -- out_dir [t]

var _n := 0
var _out := ""
var _bodies: Array = []
var _cams: Array = []
var _vp: Array = []
var _off := Vector3(0.15, 0.1, 0.65)

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://"
	var t := float(args[1]) if args.size() > 1 else 0.5
	if args.size() > 4: _off = Vector3(float(args[2]), float(args[3]), float(args[4]))
	var world := Node3D.new()
	get_root().add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.45)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.add_child(env)
	var i := 0
	for id in ["nga_mi", "vo_dang", "thieu_lam"]:
		var s := Sects.get_sect(id)
		var a := Avatar.new(s.look.duplicate())
		a.position = Vector3(i * 3.0, 0, 0)
		a.rotation.y = PI / 2
		world.add_child(a)
		_bodies.append([id, a, s.style, t])
		i += 1

func _process(_d: float) -> bool:
	_n += 1
	for b in _bodies:
		var a: Avatar = b[1]
		var ic: Array = AnimMap.idle_clip(b[2], str(a.look.get("model", "")))
		a.pose(ic[0], a.clip_len(ic[0]) * float(b[3]), 0.0)
		a.finish(0.016)
	if _n == 6:
		var cam := Camera3D.new()
		get_root().add_child(cam)
		cam.current = true
		cam.fov = 30
		_cams.append(cam)
	if _n >= 8 and _n % 3 == 2:
		var k := (_n - 8) / 3
		var views := []
		for b in _bodies:
			var a: Avatar = b[1]
			for side in ["r", "l"]:
				views.append([b[0] + "_" + side, a.hand_r_tip if side == "r" else a.hand_l_tip, a])
			views.append([b[0] + "_full", null, a])
		if k > 0:
			get_root().get_viewport().get_texture().get_image().save_png(_out + "/" + views[k - 1][0] + ".png")
		if k >= views.size():
			return true
		var v: Array = views[k]
		var cam: Camera3D = _cams[0]
		var a2: Avatar = v[2]
		if v[1] == null:
			var c := a2.global_position + Vector3(0, 1.0, 0)
			cam.global_position = c + Vector3(0.6, 0.2, 3.2)
			cam.look_at(c)
		else:
			var c: Vector3 = (v[1] as Node3D).global_position
			cam.global_position = c + _off
			cam.look_at(c)
	return false
