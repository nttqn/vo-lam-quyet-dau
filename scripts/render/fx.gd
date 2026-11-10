class_name Fx
extends Node3D
## Hit sparks, shockwaves, floating damage numbers and projectile visuals.

var _projs := {}     # id -> Node3D
var _num_font: Font

func _ready() -> void:
	_num_font = load("res://assets/fonts/BeVietnamPro-Bold.ttf")

# Godot frees a material shader as soon as no material uses that feature set;
# the next spark then recompiles it (a hitch, and on Mali phones each compile
# grows driver memory until the game crashes). Keep one copy of every
# feature combination alive for the whole session.
static var _pins := {}

static func _pin(m: StandardMaterial3D) -> StandardMaterial3D:
	var k := "%d/%d/%d/%d/%d/%s/%s" % [m.shading_mode, m.transparency, m.blend_mode, m.cull_mode, m.billboard_mode, m.emission_enabled, m.metallic > 0.0]
	if not _pins.has(k):
		_pins[k] = m.duplicate()
	return m

func _unshaded(col: Color, add := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _pin(m)

func spark(pos: Vector3, col: Color, heavy: bool, fx: String) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 26 if heavy else 14
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3(0, 0.3, 1)
	p.spread = 180
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 8.0 if heavy else 5.0
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var mm := _unshaded(col)
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_pin(mm)
	q.material = mm
	p.mesh = q
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.position = pos
	add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
	# core flash
	var s := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	s.mesh = sm
	var fm := _unshaded(Color(col.r, col.g, col.b, 0.9))
	s.material_override = fm
	s.position = pos
	s.scale = Vector3.ONE * 0.15
	add_child(s)
	var big := 0.9 if heavy else 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * big, 0.12)
	tw.tween_property(fm, "albedo_color:a", 0.0, 0.16)
	tw.chain().tween_callback(s.queue_free)
	if heavy or fx in ["palm", "roar", "lotus"]:
		ring(pos, col, 1.4 if heavy else 0.8)
	if fx == "slash":
		_slash_line(pos, col)

func _slash_line(pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.04, 0.02)
	mi.mesh = bm
	var m := _unshaded(Color(1, 1, 1, 0.95))
	mi.material_override = m
	mi.position = pos + Vector3(0, 0, 0.3)
	mi.rotation.z = randf_range(-0.9, 0.9)
	mi.scale = Vector3(0.1, 1, 1)
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(1, 1, 1), 0.08)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.18)
	tw.chain().tween_callback(mi.queue_free)

func ring(pos: Vector3, col: Color, size := 1.0) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	tm.rings = 20
	tm.ring_segments = 4
	mi.mesh = tm
	var m := _unshaded(Color(col.r, col.g, col.b, 0.45))
	mi.material_override = m
	mi.position = pos
	mi.rotation.x = PI * 0.5
	mi.rotation.y = 0.5
	mi.scale = Vector3.ONE * 0.2
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 1.3 * size, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(mi.queue_free)

func ground_ring(x: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.45
	tm.outer_radius = 0.5
	tm.rings = 24
	tm.ring_segments = 4
	mi.mesh = tm
	var m := _unshaded(Color(col.r, col.g, col.b, 0.9))
	mi.material_override = m
	mi.position = Vector3(x, 0.08, 0)
	mi.scale = Vector3.ONE * 0.3
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(3.5, 1, 3.5), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_callback(mi.queue_free)

func dust(x: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 18
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 70
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	p.gravity = Vector3(0, -1, 0)
	var q := SphereMesh.new()
	q.radius = 0.05
	q.height = 0.1
	q.radial_segments = 6
	q.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.8, 0.75, 0.65, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = _pin(m)
	p.mesh = q
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	p.position = Vector3(x, 0.1, 0)
	add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func number(pos: Vector3, amount: float, crit: bool, col := Color(1, 0.95, 0.8)) -> void:
	var l := Label3D.new()
	l.text = str(int(round(amount))) + ("!" if crit else "")
	l.font = _num_font
	l.font_size = 72 if crit else 52
	l.outline_size = 14
	l.outline_modulate = Color(0.15, 0.02, 0.02)
	l.modulate = Color(1, 0.85, 0.2) if crit else col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.0035
	l.position = pos + Vector3(randf_range(-0.2, 0.2), 0.0, 0.5)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.45, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)

func text(pos: Vector3, s: String, col: Color) -> void:
	var l := Label3D.new()
	l.text = s
	l.font = _num_font
	l.font_size = 44
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0)
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.005
	l.position = pos
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.6, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------- projectiles
func add_proj(p: Dictionary, col: Color) -> void:
	var n := Node3D.new()
	var vis: String = p.vis
	var dir: float = p.dir
	match vis:
		"knife", "needle":
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.32 if vis == "knife" else 0.24, 0.035 if vis == "knife" else 0.012, 0.02)
			mi.mesh = bm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.85, 0.88, 0.95) if vis == "knife" else Color(0.5, 1.0, 0.4)
			m.metallic = 0.6
			m.roughness = 0.2
			m.emission_enabled = vis == "needle"
			m.emission = Color(0.3, 1.0, 0.2)
			mi.material_override = _pin(m)
			n.add_child(mi)
		"crescent", "sword":
			var mi := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.5
			tm.outer_radius = 0.6
			tm.rings = 16
			tm.ring_segments = 4
			mi.mesh = tm
			mi.material_override = _unshaded(Color(col.r, col.g, col.b, 0.85))
			mi.scale = Vector3(0.6, 1.0, 1.2)
			mi.rotation.x = PI * 0.5
			mi.rotation.y = PI * 0.5
			n.add_child(mi)
			if vis == "sword":
				var b := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.9, 0.05, 0.02)
				b.mesh = bm
				b.material_override = _unshaded(Color(0.8, 0.95, 1.0, 0.95))
				n.add_child(b)
				mi.scale *= 0.5
		"dragon":
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.32
			sm.height = 0.64
			mi.mesh = sm
			mi.material_override = _unshaded(Color(1.0, 0.8, 0.3, 0.9))
			mi.scale = Vector3(1.6, 1, 1)
			n.add_child(mi)
			var tail := CPUParticles3D.new()
			tail.amount = 40
			tail.lifetime = 0.4
			tail.local_coords = false
			tail.direction = Vector3(-dir, 0, 0)
			tail.spread = 25
			tail.initial_velocity_min = 1
			tail.initial_velocity_max = 3
			tail.gravity = Vector3.ZERO
			var q := SphereMesh.new()
			q.radius = 0.12
			q.height = 0.24
			q.material = _unshaded(Color(1.0, 0.6, 0.2, 0.7))
			tail.mesh = q
			n.add_child(tail)
		"petal":
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.06
			mi.mesh = sm
			mi.material_override = _unshaded(Color(1.0, 0.6, 0.8, 0.95), false)
			n.add_child(mi)
		"bomb":
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.13
			sm.height = 0.26
			mi.mesh = sm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.1, 0.1, 0.1)
			mi.material_override = _pin(m)
			n.add_child(mi)
			var fuse := OmniLight3D.new()
			fuse.light_color = Color(1, 0.6, 0.2)
			fuse.light_energy = 1.5
			fuse.omni_range = 1.5
			n.add_child(fuse)
	if dir < 0:
		n.rotation.y = PI
	n.position = Vector3(p.x, p.y, 0)
	add_child(n)
	_projs[p.id] = n

func sync_projs(list: Array) -> void:
	for p in list:
		var n: Node3D = _projs.get(p.id)
		if n:
			n.position = Vector3(p.x, p.y, 0)
			if p.vis in ["knife", "needle"]:
				n.rotation.z = atan2(p.vy, absf(p.vx)) * (1.0 if p.dir > 0 else 1.0)
			elif p.vis == "petal" or p.vis == "bomb":
				n.rotation.z += 0.3

func end_proj(id: int) -> void:
	var n: Node3D = _projs.get(id)
	if n:
		n.queue_free()
		_projs.erase(id)

func clear_projs() -> void:
	for id in _projs:
		(_projs[id] as Node3D).queue_free()
	_projs.clear()
