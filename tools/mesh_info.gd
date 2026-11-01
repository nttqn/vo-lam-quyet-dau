extends SceneTree
func _init() -> void:
	for p in OS.get_cmdline_user_args():
		var n: Node = load(p).instantiate()
		print("== ", p.get_file())
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = m.mesh
			var s := ""
			for i in mesh.get_surface_count():
				var mat = mesh.surface_get_material(i)
				var tex = mat.albedo_texture if mat is StandardMaterial3D else null
				s += " [%d %s tex=%s col=%s]" % [i, mat.resource_name if mat else "-", tex.resource_path.get_file() if tex else "-", mat.albedo_color.to_html(false) if mat is StandardMaterial3D else "-"]
			print("  ", m.name, s, " skin_binds=", m.skin.get_bind_count() if m.skin else 0)
	quit()
