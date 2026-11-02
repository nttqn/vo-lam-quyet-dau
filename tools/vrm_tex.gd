extends SceneTree
## Saves each material's albedo texture of a model to <out>/<mesh>_<i>.png
##   godot --headless --path . --script res://tools/vrm_tex.gd -- res://assets/models/vrm/NgaMi.glb C:/out

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n: Node = load(args[0]).instantiate()
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if mat and mat.albedo_texture:
				var img := mat.albedo_texture.get_image()
				if img.is_compressed():
					img.decompress()
				img.save_png(args[1] + "/%s_%d.png" % [mi.name, s])
				print(mi.name, " ", s, " col ", mat.albedo_color, " size ", img.get_size(), " emission ", mat.emission_enabled, " ", mat.emission)
	quit()
