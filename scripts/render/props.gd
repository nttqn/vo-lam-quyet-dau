class_name Props
extends RefCounted
## Painted/Meshy scenery that replaces the arena's built shapes when the files exist.
##   models: assets/models/props/<name>.glb  (pagoda, gate, lantern, rock, pine,
##           tree, boat, wall, brazier, …) — standing upright, base on the ground;
##           scaled to the height the arena asks for, centred on its footprint.
##   backdrops: assets/art/bg_<theme>.png|webp — wide painting behind the arena.

const MODEL_DIR := "res://assets/models/props/"
const ART_DIR := "res://assets/art/"
const BAKED_LIT := 0.7

static var _cache := {}

static func model_file(name: String) -> String:
	for ext in [".glb", ".fbx", ".gltf"]:
		if ResourceLoader.exists(MODEL_DIR + name + ext):
			return MODEL_DIR + name + ext
	return ""

static func has(name: String) -> bool:
	return model_file(name) != ""

## Places a prop model (height in metres, yaw in degrees); null when the file
## is not in the game, so the caller falls back to its built shape.
static func place(parent: Node3D, name: String, pos: Vector3, height: float, yaw := 0.0, shadow := true) -> Node3D:
	var path := model_file(name)
	if path == "":
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var inst: Node3D = (_cache[path] as PackedScene).instantiate()
	for ap in inst.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	var box := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var n: Node = m3
		while n != inst and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var bb: AABB = xf * m3.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in m3.mesh.get_surface_count():
			var src = m3.get_active_material(s)
			if src is StandardMaterial3D:
				var nm := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
				nm.albedo_color = nm.albedo_color * Color(BAKED_LIT, BAKED_LIT, BAKED_LIT)
				nm.roughness = 0.9
				nm.metallic_specular = 0.2
				m3.set_surface_override_material(s, nm)
	if first or box.size.y <= 0.0001:
		inst.free()
		return null
	var k := height / box.size.y
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = yaw
	inst.scale = Vector3.ONE * k
	var c := box.get_center()
	inst.position = -Vector3(c.x, box.position.y, c.z) * k
	holder.add_child(inst)
	parent.add_child(holder)
	return holder

static func backdrop(theme: String) -> Texture2D:
	for ext in [".webp", ".png", ".jpg"]:
		var p: String = ART_DIR + "bg_" + theme + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null
