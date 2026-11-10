class_name Arena
extends Node3D
## Low-poly 3D fighting stage. Fighters stand on the z=0 line; the camera
## looks from +Z. Everything behind (z<0) is scenery, layered for depth.

var theme: String
var rng := RandomNumberGenerator.new()
var _mats := {}
var _sway: Array[Node3D] = []
var _water: MeshInstance3D

const THEMES := {
	"temple": {"sky_top": Color(0.28, 0.45, 0.72), "sky_hor": Color(0.86, 0.78, 0.64), "ground": Color(0.42, 0.37, 0.32), "fog": Color(0.8, 0.74, 0.64), "sun": Color(1.0, 0.9, 0.76), "sun_e": 1.05, "amb": 0.5},
	"bamboo": {"sky_top": Color(0.26, 0.42, 0.4), "sky_hor": Color(0.62, 0.72, 0.58), "ground": Color(0.26, 0.3, 0.17), "fog": Color(0.5, 0.62, 0.48), "sun": Color(0.95, 1.0, 0.85), "sun_e": 1.1, "amb": 0.6},
	"river": {"sky_top": Color(0.35, 0.45, 0.7), "sky_hor": Color(0.95, 0.72, 0.55), "ground": Color(0.52, 0.42, 0.3), "fog": Color(0.9, 0.72, 0.6), "sun": Color(1.0, 0.8, 0.6), "sun_e": 1.2, "amb": 0.5},
	"snow": {"sky_top": Color(0.55, 0.62, 0.75), "sky_hor": Color(0.88, 0.9, 0.94), "ground": Color(0.88, 0.9, 0.95), "fog": Color(0.85, 0.88, 0.94), "sun": Color(0.95, 0.97, 1.0), "sun_e": 1.0, "amb": 0.7},
	"desert": {"sky_top": Color(0.4, 0.55, 0.8), "sky_hor": Color(0.95, 0.82, 0.6), "ground": Color(0.8, 0.65, 0.42), "fog": Color(0.93, 0.8, 0.6), "sun": Color(1.0, 0.9, 0.7), "sun_e": 1.5, "amb": 0.55},
	"demon": {"sky_top": Color(0.12, 0.04, 0.08), "sky_hor": Color(0.55, 0.15, 0.1), "ground": Color(0.25, 0.2, 0.2), "fog": Color(0.35, 0.1, 0.08), "sun": Color(1.0, 0.5, 0.35), "sun_e": 0.9, "amb": 0.4},
	"peak": {"sky_top": Color(0.2, 0.3, 0.6), "sky_hor": Color(0.95, 0.65, 0.5), "ground": Color(0.5, 0.48, 0.48), "fog": Color(0.9, 0.7, 0.62), "sun": Color(1.0, 0.85, 0.7), "sun_e": 1.2, "amb": 0.5},
	"night": {"sky_top": Color(0.04, 0.05, 0.14), "sky_hor": Color(0.2, 0.22, 0.38), "ground": Color(0.3, 0.3, 0.34), "fog": Color(0.15, 0.17, 0.3), "sun": Color(0.6, 0.7, 1.0), "sun_e": 0.6, "amb": 0.45},
}

func _init(t := "temple", seed_ := 1) -> void:
	theme = t
	rng.seed = seed_

func m(col: Color, rough := 0.9) -> StandardMaterial3D:
	var key := col.to_html() + str(rough)
	if _mats.has(key):
		return _mats[key]
	var mm := StandardMaterial3D.new()
	mm.albedo_color = col
	mm.roughness = rough
	_mats[key] = mm
	return mm

func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

func cyl(t: float, b: float, h: float, seg := 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = t
	c.bottom_radius = b
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _ready() -> void:
	var th: Dictionary = THEMES.get(theme, THEMES["temple"])
	_environment(th)
	_ground(th)
	if Diag.on("no_props"):
		return
	match theme:
		"temple": _temple()
		"bamboo": _bamboo()
		"river": _river()
		"snow": _snow()
		"desert": _desert()
		"demon": _demon()
		"peak": _peak()
		"night": _night()
	_mountains(th)

func _environment(th: Dictionary) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = th.sky_top
	sm.sky_horizon_color = th.sky_hor
	sm.ground_horizon_color = th.sky_hor
	sm.ground_bottom_color = (th.ground as Color).darkened(0.3)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_COLOR if Diag.on("no_sky") else Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if Diag.on("no_ambient_sky") else Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = th.sky_top
	env.ambient_light_energy = th.amb * 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.78
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.06
	env.fog_enabled = not Diag.on("no_fog")
	env.fog_light_color = th.fog
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	env.glow_enabled = not Diag.on("no_glow")
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = th.sun
	sun.light_energy = th.sun_e
	sun.rotation_degrees = Vector3(-38, 28, 0)
	sun.shadow_enabled = not Diag.on("no_shadow")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	sun.shadow_blur = 2.2
	sun.shadow_bias = 0.03
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = (th.sky_top as Color).lerp(Color.WHITE, 0.5)
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-20, -150, 0)
	add_child(fill)
	# back rim light: carves the fighters out of the background
	var rim := DirectionalLight3D.new()
	rim.light_color = (th.sun as Color).lerp(Color(1.0, 0.85, 0.6), 0.5)
	rim.light_energy = 0.85 * float(th.sun_e)
	rim.rotation_degrees = Vector3(-18, 180 - 30, 0)
	rim.light_specular = 1.5
	add_child(rim)

func _ground(th: Dictionary) -> void:
	var g: Color = th.ground
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 60)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = g
	gm.roughness = 1.0
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.05
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var grad := Gradient.new()
	grad.set_color(0, g.darkened(0.35))
	grad.set_color(1, g.darkened(0.05))
	tex.color_ramp = grad
	if not Diag.on("no_noise"):
		gm.albedo_texture = tex
	gm.albedo_color = Color.WHITE
	gm.uv1_scale = Vector3(8, 6, 1)
	_mesh(pm, gm, Vector3(0, 0, -10), Vector3.ZERO, Vector3.ONE, false)
	# fighting floor: stone slabs / platform for most themes
	if theme in ["temple", "peak", "demon", "night"] and not Diag.on("no_floor"):
		var slab := m(g.darkened(0.02) if theme != "demon" else Color(0.3, 0.22, 0.2), 0.8)
		var slab2 := m(g.darkened(0.1) if theme != "demon" else Color(0.24, 0.18, 0.17), 0.8)
		for ix in range(-9, 10):
			for iz in range(-3, 2):
				var mm := slab if (ix + iz) % 2 == 0 else slab2
				_mesh(box(1.96, 0.08, 1.96), mm, Vector3(ix * 2.0, 0.0, iz * 2.0 + 0.5), Vector3.ZERO, Vector3.ONE, false)

func _mountains(th: Dictionary) -> void:
	var far: Color = (th.sky_top as Color).lerp(th.fog, 0.35).darkened(0.15)
	for i in 14:
		var x := -60.0 + i * 9.0 + rng.randf_range(-3, 3)
		var h := rng.randf_range(10, 24)
		var cm := cyl(0.0, rng.randf_range(7, 12), h, 6)
		var col := far.darkened(rng.randf_range(0.05, 0.2))
		if theme == "snow":
			col = Color(0.75, 0.8, 0.9).darkened(rng.randf_range(0, 0.15))
		_mesh(cm, m(col), Vector3(x, h * 0.5 - 1.0, -45 - rng.randf_range(0, 10)), Vector3(0, rng.randf_range(0, 60), 0), Vector3.ONE, false)
	for i in 10:
		var x := -40.0 + i * 9.0 + rng.randf_range(-3, 3)
		var h := rng.randf_range(5, 11)
		var col2: Color = (th.ground as Color).lerp(far, 0.55).darkened(0.1)
		if theme == "bamboo" or theme == "river":
			col2 = Color(0.3, 0.42, 0.3).lerp(far, 0.45)
		_mesh(cyl(0.0, rng.randf_range(5, 8), h, 6), m(col2), Vector3(x, h * 0.5 - 0.5, -28 - rng.randf_range(0, 6)), Vector3(0, rng.randf_range(0, 60), 0), Vector3.ONE, false)

# ------------------------------------------------------------ props
func pagoda(pos: Vector3, floors: int, s := 1.0, wall := Color(0.62, 0.15, 0.12), roof := Color(0.2, 0.22, 0.26)) -> void:
	var y := 0.0
	var w := 4.0 * s
	_mesh(box(w + 0.6, 0.5 * s, w + 0.6), m(Color(0.6, 0.58, 0.52)), pos + Vector3(0, 0.25 * s, 0))
	y = 0.5 * s
	for f in floors:
		var fh := 1.8 * s * (1.0 - f * 0.08)
		_mesh(box(w, fh, w), m(wall), pos + Vector3(0, y + fh * 0.5, 0))
		# pillars
		for px in [-1, 1]:
			_mesh(cyl(0.12 * s, 0.12 * s, fh, 6), m(wall.darkened(0.3)), pos + Vector3(px * (w * 0.5 + 0.05), y + fh * 0.5, w * 0.5 + 0.05))
		y += fh
		var rw := w + 1.6 * s
		var r := _mesh(cyl(rw * 0.32, rw * 0.78, 0.7 * s, 4), m(roof), pos + Vector3(0, y + 0.3 * s, 0), Vector3(0, 45, 0))
		r.scale = Vector3(1, 1, 1)
		# upturned eave tips
		for cx in [-1, 1]:
			for cz in [-1, 1]:
				_mesh(cyl(0.0, 0.12 * s, 0.5 * s, 4), m(roof), pos + Vector3(cx * rw * 0.55, y + 0.15 * s, cz * rw * 0.55), Vector3(cz * -35, 0, cx * 35))
		y += 0.6 * s
		w *= 0.78
	_mesh(cyl(0.0, 0.25 * s, 1.2 * s, 6), m(Color(0.8, 0.62, 0.2), 0.4), pos + Vector3(0, y + 0.6 * s, 0))

func tree(pos: Vector3, s := 1.0, col := Color(0.22, 0.4, 0.22)) -> void:
	_mesh(cyl(0.12 * s, 0.2 * s, 2.0 * s, 6), m(Color(0.32, 0.22, 0.14)), pos + Vector3(0, 1.0 * s, 0))
	for i in 3:
		var r := (1.5 - i * 0.35) * s
		_mesh(cyl(0.0, r, 1.6 * s, 7), m(col.lightened(i * 0.05)), pos + Vector3(0, (2.0 + i * 0.9) * s, 0), Vector3(0, i * 20, 0))

func pine(pos: Vector3, s := 1.0, snow := false) -> void:
	_mesh(cyl(0.08 * s, 0.14 * s, 1.0 * s, 6), m(Color(0.3, 0.2, 0.13)), pos + Vector3(0, 0.5 * s, 0))
	for i in 4:
		var col := Color(0.16, 0.3, 0.2) if not snow else Color(0.85, 0.9, 0.95)
		_mesh(cyl(0.0, (1.2 - i * 0.25) * s, 1.1 * s, 7), m(col.lightened(i * 0.04)), pos + Vector3(0, (1.0 + i * 0.7) * s, 0), Vector3(0, i * 25, 0))

func lantern(pos: Vector3, col := Color(0.95, 0.3, 0.15), light := false) -> void:
	_mesh(cyl(0.04, 0.04, 2.4, 6), m(Color(0.2, 0.15, 0.1)), pos + Vector3(0, 1.2, 0))
	var lm := StandardMaterial3D.new()
	lm.albedo_color = col
	lm.emission_enabled = true
	lm.emission = col
	lm.emission_energy_multiplier = 1.6
	_mesh(SphereMesh.new(), lm, pos + Vector3(0, 2.5, 0), Vector3.ZERO, Vector3(0.36, 0.48, 0.36), false)
	if light and not Diag.on("no_lights"):
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 1.5
		l.omni_range = 6.0
		l.position = pos + Vector3(0, 2.5, 0.3)
		add_child(l)

func rock(pos: Vector3, s := 1.0, col := Color(0.45, 0.43, 0.42)) -> void:
	var sm := SphereMesh.new()
	sm.radial_segments = 6
	sm.rings = 3
	_mesh(sm, m(col), pos, Vector3(rng.randf_range(0, 40), rng.randf_range(0, 180), 0), Vector3(1.4, 0.8, 1.1) * s)

func gate(pos: Vector3, s := 1.0, col := Color(0.65, 0.14, 0.1)) -> void:
	for px in [-1, 1]:
		_mesh(cyl(0.2 * s, 0.2 * s, 4.0 * s, 8), m(col), pos + Vector3(px * 2.2 * s, 2.0 * s, 0))
	_mesh(box(5.6 * s, 0.3 * s, 0.4 * s), m(col), pos + Vector3(0, 3.4 * s, 0))
	_mesh(box(6.4 * s, 0.35 * s, 0.6 * s), m(Color(0.18, 0.18, 0.2)), pos + Vector3(0, 4.1 * s, 0))
	_mesh(box(1.2 * s, 0.6 * s, 0.1 * s), m(Color(0.1, 0.1, 0.1)), pos + Vector3(0, 3.75 * s, 0.25 * s))

# ------------------------------------------------------------ themes
func _temple() -> void:
	pagoda(Vector3(-2, 0, -16), 3, 1.0)
	pagoda(Vector3(10, 0, -20), 2, 0.9)
	pagoda(Vector3(-14, 0, -19), 2, 0.8)
	_mesh(box(40, 1.4, 0.5), m(Color(0.7, 0.3, 0.22)), Vector3(0, 0.7, -9))
	_mesh(box(40, 0.2, 0.8), m(Color(0.25, 0.25, 0.28)), Vector3(0, 1.5, -9))
	for x in [-9, -3, 3, 9]:
		lantern(Vector3(x, 0, -7))
	for x in [-16, 15, -20, 20]:
		tree(Vector3(x, 0, -11 + rng.randf_range(-2, 2)), rng.randf_range(0.9, 1.3), Color(0.3, 0.45, 0.25))
	# incense burner
	_mesh(cyl(0.5, 0.35, 0.7, 8), m(Color(0.35, 0.3, 0.2), 0.5), Vector3(-6.5, 0.35, -5.5))

func _bamboo() -> void:
	for i in 140:
		var x := rng.randf_range(-30, 30)
		var z := rng.randf_range(-24, -5)
		if absf(x) < 2 and z > -8:
			continue
		var h := rng.randf_range(6, 12)
		var col := Color(0.35, 0.55, 0.25).lerp(Color(0.6, 0.7, 0.35), rng.randf())
		var stalk := _mesh(cyl(0.07, 0.09, h, 6), m(col, 0.6), Vector3(x, h * 0.5, z), Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4)))
		if rng.randf() < 0.5:
			_mesh(SphereMesh.new(), m(Color(0.3, 0.5, 0.22)), Vector3(x, h - 0.5, z), Vector3.ZERO, Vector3(1.6, 0.6, 1.6), false)
		_sway.append(stalk)
	for i in 8:
		rock(Vector3(rng.randf_range(-14, 14), 0.2, rng.randf_range(-6, -3)), rng.randf_range(0.4, 0.8))

func _river() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 14)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.25, 0.45, 0.55, 0.85)
	wm.roughness = 0.1
	wm.metallic = 0.3
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water = _mesh(pm, wm, Vector3(0, 0.03, -14), Vector3.ZERO, Vector3.ONE, false)
	# wooden pier as the fight floor
	for ix in range(-10, 11):
		_mesh(box(1.9, 0.12, 4.0), m(Color(0.5, 0.36, 0.22) if ix % 2 == 0 else Color(0.45, 0.32, 0.2)), Vector3(ix * 2.0, 0.06, 0.3), Vector3.ZERO, Vector3.ONE, false)
	for x in range(-18, 19, 4):
		_mesh(cyl(0.12, 0.12, 1.2, 6), m(Color(0.35, 0.25, 0.15)), Vector3(x, 0.3, -1.8))
	# boats
	for b in [Vector3(-8, 0.1, -12), Vector3(9, 0.1, -16)]:
		_mesh(box(4, 0.5, 1.2), m(Color(0.4, 0.27, 0.15)), b)
		_mesh(cyl(0.6, 0.6, 2.0, 8), m(Color(0.75, 0.65, 0.45)), b + Vector3(0, 0.6, 0), Vector3(90, 0, 90), Vector3(1, 1, 0.6))
	for x in [-20, -14, 14, 21]:
		tree(Vector3(x, 0, -24), 1.4, Color(0.25, 0.42, 0.25))

func _snow() -> void:
	for i in 26:
		pine(Vector3(rng.randf_range(-28, 28), 0, rng.randf_range(-24, -6)), rng.randf_range(1.0, 2.0), true)
	for i in 6:
		rock(Vector3(rng.randf_range(-12, 12), 0.2, rng.randf_range(-6, -3)), rng.randf_range(0.5, 1.0), Color(0.75, 0.78, 0.85))
	pagoda(Vector3(4, 0, -18), 2, 0.8, Color(0.45, 0.2, 0.18), Color(0.85, 0.88, 0.93))
	var p := CPUParticles3D.new()
	p.amount = 300
	p.lifetime = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(18, 0.5, 8)
	p.position = Vector3(0, 9, -3)
	p.direction = Vector3(0.2, -1, 0)
	p.spread = 20
	p.gravity = Vector3(0, -0.6, 0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.albedo_color = Color(1, 1, 1, 0.9)
	qm.material = sm
	p.mesh = qm
	add_child(p)

func _desert() -> void:
	for i in 10:
		var s := rng.randf_range(2, 5)
		var dm := SphereMesh.new()
		dm.radial_segments = 8
		dm.rings = 4
		_mesh(dm, m(Color(0.85, 0.7, 0.45).darkened(rng.randf() * 0.1)), Vector3(rng.randf_range(-30, 30), -s * 0.4, rng.randf_range(-26, -8)), Vector3.ZERO, Vector3(s * 2, s * 0.6, s), false)
	# ruined fort wall
	for i in 7:
		var h := rng.randf_range(2.5, 4.5)
		_mesh(box(3.0, h, 1.2), m(Color(0.7, 0.55, 0.38)), Vector3(-12 + i * 3.2, h * 0.5, -14))
	gate(Vector3(10, 0, -12), 1.0, Color(0.55, 0.35, 0.22))
	for i in 5:
		rock(Vector3(rng.randf_range(-14, 14), 0.2, rng.randf_range(-6, -3)), rng.randf_range(0.4, 0.9), Color(0.62, 0.48, 0.34))

func _demon() -> void:
	pagoda(Vector3(0, 0, -18), 3, 1.2, Color(0.2, 0.08, 0.08), Color(0.08, 0.06, 0.06))
	for x in [-8, -4, 4, 8]:
		lantern(Vector3(x, 0, -6), Color(1.0, 0.2, 0.1), true)
	for x in [-13, 13]:
		_mesh(cyl(0.6, 0.8, 1.0, 8), m(Color(0.2, 0.18, 0.18)), Vector3(x, 0.5, -5))
		var f := CPUParticles3D.new()
		f.amount = 40
		f.lifetime = 0.8
		f.position = Vector3(x, 1.0, -5)
		f.direction = Vector3.UP
		f.spread = 15
		f.gravity = Vector3(0, 2, 0)
		f.initial_velocity_min = 1
		f.initial_velocity_max = 2
		f.scale_amount_min = 0.5
		var qm := SphereMesh.new()
		qm.radius = 0.15
		qm.height = 0.3
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color(1.0, 0.45, 0.1)
		qm.material = fm
		f.mesh = qm
		add_child(f)
		var l := OmniLight3D.new()
		l.light_color = Color(1, 0.5, 0.2)
		l.light_energy = 2.0
		l.omni_range = 8
		l.position = Vector3(x, 2, -4)
		add_child(l)
	for i in 6:
		rock(Vector3(rng.randf_range(-20, 20), 0.3, rng.randf_range(-14, -8)), rng.randf_range(1, 2), Color(0.22, 0.18, 0.18))

func _peak() -> void:
	# cliff platform: the floor ends behind, sea of clouds below
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(1, 0.95, 0.92, 0.85)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 18:
		var sm := SphereMesh.new()
		sm.radial_segments = 8
		sm.rings = 4
		_mesh(sm, cm, Vector3(rng.randf_range(-40, 40), -2.5, rng.randf_range(-40, -14)), Vector3.ZERO, Vector3(rng.randf_range(6, 12), 2, rng.randf_range(4, 8)), false)
	for i in 5:
		pine(Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-9, -6)), rng.randf_range(1.2, 1.8))
	_mesh(cyl(0.6, 0.8, 0.9, 6), m(Color(0.6, 0.6, 0.6)), Vector3(-7, 0.45, -5))
	_mesh(box(0.9, 2.2, 0.3), m(Color(0.55, 0.55, 0.55)), Vector3(7, 1.1, -6))   # stele

func _night() -> void:
	gate(Vector3(0, 0, -12), 1.2)
	for x in [-10, -5, 5, 10]:
		lantern(Vector3(x, 0, -8), Color(1.0, 0.75, 0.35), true)
	for x in [-18, 18, -24, 24]:
		tree(Vector3(x, 0, -14), 1.4, Color(0.15, 0.22, 0.18))
	var moon := StandardMaterial3D.new()
	moon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon.albedo_color = Color(1, 0.97, 0.85)
	_mesh(SphereMesh.new(), moon, Vector3(14, 22, -60), Vector3.ZERO, Vector3(5, 5, 5), false)

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in _sway.size():
		var n := _sway[i]
		n.rotation.z = sin(t * 0.8 + i * 0.7) * 0.03
