class_name Weapons
extends RefCounted
## Builds weapon meshes under a grip node. Convention: the blade/shaft runs
## along the grip's -Y axis; returns the tip marker node.

static var _mats := {}

static func mat(col: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	var key := col.to_html() + str(rough) + str(metal)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	_mats[key] = m
	return m

static func seg(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

static func cyl(t: float, b: float, h: float, seg_n := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = t
	c.bottom_radius = b
	c.height = h
	c.radial_segments = seg_n
	c.rings = 1
	return c

static func sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 5
	return s

# ------------------------------------------------------------- model files
## Meshy weapon models: assets/models/weapons/<kind>_<stage>.glb (stage 1 = tiers
## 1-2, 2 = tiers 3-5, 3 = tiers 6-7), or <kind>.glb for every tier. Modelled
## standing straight up with the handle at the bottom; scaled to the length
## below and gripped at the given fraction of it, measured from the bottom.
const MODEL_DIR := "res://assets/models/weapons/"
## kind -> [length m, grip fraction from the bottom, girth (cross-section scale)]
const SPEC := {"sword": [1.0, 0.09, 1.0], "dual_blade": [0.64, 0.12, 1.0], "staff": [1.8, 0.29, 0.5], "dagger": [0.36, 0.18, 1.0], "saber": [0.95, 0.1, 1.0], "spear": [2.0, 0.3, 0.6]}
const BAKED_LIT := 0.6

static func stage(tier: int) -> int:
	return 1 if tier <= 2 else (2 if tier <= 5 else 3)

static func model_file(kind: String, tier: int) -> String:
	for p in ["%s%s_%d" % [MODEL_DIR, kind, stage(tier)], MODEL_DIR + kind]:
		for ext in [".glb", ".fbx"]:
			if ResourceLoader.exists(p + ext):
				return p + ext
	return ""

static func _model(kind: String, tier: int, g: Node3D) -> Node3D:
	var path := model_file(kind, tier)
	if path == "" or not SPEC.has(kind):
		return null
	var inst: Node3D = load(path).instantiate()
	for ap in inst.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	# bounds in the model root space
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
		# baked lighting in the texture: dim it like the sect models
		var m3 := mi as MeshInstance3D
		for s in m3.mesh.get_surface_count():
			var src = m3.get_active_material(s)
			if src is StandardMaterial3D:
				var nm := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
				nm.albedo_color = nm.albedo_color * Color(BAKED_LIT, BAKED_LIT, BAKED_LIT)
				nm.roughness = 0.75
				m3.set_surface_override_material(s, nm)
	if first or box.size.y <= 0.0001:
		inst.free()
		return null
	var len_m: float = SPEC[kind][0]
	var frac: float = SPEC[kind][1]
	var k := len_m / box.size.y
	var grip_y := box.position.y + box.size.y * frac
	var holder := Node3D.new()
	holder.rotation_degrees = Vector3(180, 0, 0)   # model up -> blade along -Y
	g.add_child(holder)
	var girth: float = SPEC[kind][2]
	inst.scale = Vector3(k * girth, k, k * girth)   # thinner staffs: Meshy makes them chunky
	var c := box.get_center()
	inst.position = -Vector3(c.x * girth, grip_y, c.z * girth) * k
	holder.add_child(inst)
	var tip := Node3D.new()
	tip.position = Vector3(0, -(box.end.y - grip_y) * k, 0)
	g.add_child(tip)
	return tip

## kind: sword | saber | staff | spear | dual_blade | dagger | fan
static func build(kind: String, g: Node3D, tier := 1) -> Node3D:
	var from_file := _model(kind, tier, g)
	if from_file:
		return from_file
	var steel := mat(Color(0.85, 0.88, 0.93), 0.22, 0.7)
	var wood := mat(Color(0.42, 0.26, 0.13), 0.7)
	var gold := mat(Color(0.86, 0.66, 0.22), 0.35, 0.6)
	var grip := mat(Color(0.25, 0.07, 0.05), 0.8)
	var tip := Node3D.new()
	match kind:
		"sword":
			seg(g, cyl(0.016, 0.016, 0.17), grip, Vector3(0, 0.0, 0))
			seg(g, box(0.05, 0.022, 0.15), gold, Vector3(0, -0.09, 0))
			seg(g, box(0.042, 0.74, 0.01), steel, Vector3(0, -0.47, 0))
			seg(g, box(0.03, 0.05, 0.01), steel, Vector3(0, -0.855, 0), Vector3(0, 0, 45))
			seg(g, box(0.018, 0.14, 0.008), mat(Color(0.8, 0.1, 0.1)), Vector3(0, 0.15, 0))
			tip.position = Vector3(0, -0.87, 0)
		"dual_blade":
			seg(g, cyl(0.014, 0.014, 0.12), grip, Vector3.ZERO)
			seg(g, box(0.04, 0.02, 0.1), gold, Vector3(0, -0.065, 0))
			seg(g, box(0.036, 0.5, 0.009), steel, Vector3(0, -0.32, 0))
			tip.position = Vector3(0, -0.57, 0)
		"saber":
			seg(g, cyl(0.018, 0.018, 0.17), grip, Vector3.ZERO)
			seg(g, cyl(0.05, 0.05, 0.02), gold, Vector3(0, -0.09, 0))
			seg(g, box(0.08, 0.7, 0.01), steel, Vector3(0.02, -0.44, 0), Vector3(0, 0, -4))
			tip.position = Vector3(0.04, -0.8, 0)
		"staff":
			seg(g, cyl(0.022, 0.022, 1.8), wood, Vector3(0, -0.35, 0))
			seg(g, cyl(0.028, 0.028, 0.08), gold, Vector3(0, -1.22, 0))
			seg(g, cyl(0.028, 0.028, 0.08), gold, Vector3(0, 0.52, 0))
			tip.position = Vector3(0, -1.24, 0)
		"spear":
			seg(g, cyl(0.018, 0.018, 1.9), wood, Vector3(0, -0.4, 0))
			seg(g, cyl(0.0, 0.035, 0.24, 6), steel, Vector3(0, -1.47, 0), Vector3(180, 0, 0))
			tip.position = Vector3(0, -1.58, 0)
		"dagger":
			seg(g, cyl(0.014, 0.014, 0.1), grip, Vector3.ZERO)
			seg(g, box(0.03, 0.25, 0.008), steel, Vector3(0, -0.18, 0))
			tip.position = Vector3(0, -0.3, 0)
		"fan":
			seg(g, cyl(0.02, 0.22, 0.01, 7), mat(Color(0.95, 0.92, 0.82)), Vector3(0, -0.12, 0), Vector3(90, 0, 0))
			tip.position = Vector3(0, -0.28, 0)
		_:
			tip.position = Vector3.ZERO
	g.add_child(tip)
	return tip
