extends SceneTree
## Lists every texture a model's materials use, with size and source path.
##   godot --headless --path . --script res://tools/tex_check.gd -- res://assets/models/chars/ThieuLam.fbx
func _init() -> void:
	var n: Node = load(OS.get_cmdline_user_args()[0]).instantiate()
	var seen := {}
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var mat = m.surface_get_material(s)
			if mat is BaseMaterial3D:
				for p in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "emission_texture", "orm_texture"]:
					var t = mat.get(p)
					if t is Texture2D and not seen.has(t):
						seen[t] = true
						print(p, " ", t.get_width(), "x", t.get_height(), " ", t.resource_path, " ", t.get_class())
	n.free()
	quit()
