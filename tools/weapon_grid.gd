extends SceneTree
## Each weapon model upright, normalised to height 1, with tick lines every 5 %
## of its height (thick every 25 %) to read off where the handle sits.
##   godot --path . --resolution 1500x900 --script res://tools/weapon_grid.gd -- out.png kind
var _n := 0
var _out := ""
func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var kind := args[1]
	var world := Node3D.new()
	get_root().add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.85, 0.85, 0.85)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	world.add_child(env)
	for s in 3:
		var inst: Node3D = load("res://assets/models/weapons/%s_%d.glb" % [kind, s + 1]).instantiate()
		var box := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D.IDENTITY
			var n: Node = mi
			while n != inst and n is Node3D:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			var bb: AABB = xf * (mi as MeshInstance3D).get_aabb()
			box = bb if first else box.merge(bb)
			first = false
		var k := 1.0 / box.size.y
		var holder := Node3D.new()
		holder.position = Vector3(s * 0.2 - 0.2, 0, 0)
		world.add_child(holder)
		inst.scale = Vector3.ONE * k
		inst.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k
		holder.add_child(inst)
		for t in 21:
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.12 if t % 5 == 0 else 0.06, 0.003 if t % 5 else 0.005, 0.001)
			m.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color.RED if t % 5 == 0 else Color.BLUE
			m.material_override = mat
			m.position = Vector3(0, t * 0.05, 0.3)
			holder.add_child(m)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = float(args[3]) if args.size() > 3 else 0.42
	cam.position = Vector3(0, float(args[2]) if args.size() > 2 else 0.2, 3)
	world.add_child(cam)
	cam.current = true

func _process(_d: float) -> bool:
	_n += 1
	if _n == 8:
		get_root().get_viewport().get_texture().get_image().save_png(_out)
		return true
	return false
