extends Node3D
## Renders the launcher icon (square viewport) and quits:
##   godot --path . --resolution 800x800 -- --iconshot --shot=out.png

var shot := "user://icon.png"
var n := 0

func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.35, 0.06, 0.06)
	sm.sky_horizon_color = Color(0.95, 0.55, 0.25)
	sm.ground_horizon_color = Color(0.95, 0.55, 0.25)
	sm.ground_bottom_color = Color(0.2, 0.05, 0.05)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.6, 0.5)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.85, 0.7)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-30, 40, 0)
	add_child(sun)
	# big setting sun behind the hero
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.2
	cm.bottom_radius = 2.2
	cm.height = 0.01
	cm.radial_segments = 64
	disc.mesh = cm
	disc.material_override = _unshaded(Color(1.0, 0.85, 0.45))
	disc.rotation_degrees = Vector3(90, 0, 0)
	disc.position = Vector3(0.6, 2.0, -6)
	add_child(disc)
	# mountain silhouettes
	for i in 5:
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 2.5 + i * 0.4
		c.height = 2.8 + (i % 2) * 1.2
		c.radial_segments = 4
		mi.mesh = c
		mi.material_override = _unshaded(Color(0.28, 0.07, 0.08).lerp(Color(0.5, 0.15, 0.12), (i % 3) / 3.0))
		mi.position = Vector3(-4.0 + i * 2.2, 0.3, -5.0 - (i % 2))
		add_child(mi)
	var s := Sects.get_sect("vo_dang")
	var lk: Dictionary = s.look.duplicate()
	lk.robe = Color(0.92, 0.92, 0.95)
	lk.trim = Color(0.7, 0.08, 0.06)
	lk.sash = Color(0.7, 0.08, 0.06)
	lk.pants = Color(0.15, 0.15, 0.2)
	var body := Body.new(lk)
	add_child(body)
	body.rotation.y = -0.15
	body.apply_pose(Poses.key("thrust", "sword"))
	var cam := Camera3D.new()
	cam.fov = 36
	cam.position = Vector3(0.55, 1.35, 3.0)
	add_child(cam)
	cam.look_at(Vector3(0.55, 1.15, 0))

func _process(_d: float) -> void:
	n += 1
	if n == 10:
		var img := get_viewport().get_texture().get_image()
		var sz := mini(img.get_width(), img.get_height())
		img = img.get_region(Rect2i((img.get_width() - sz) / 2, (img.get_height() - sz) / 2, sz, sz))
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
		img.save_png(shot)
		print("icon ", shot)
		get_tree().quit()
