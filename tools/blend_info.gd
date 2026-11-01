extends SceneTree
func _init() -> void:
	for p in OS.get_cmdline_user_args():
		var n: Node = load(p).instantiate()
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mesh: ArrayMesh = m.mesh
			var names := []
			for i in mesh.get_blend_shape_count(): names.append(mesh.get_blend_shape_name(i))
			print(p.get_file(), " ", m.name, " blend=", names)
	quit()
