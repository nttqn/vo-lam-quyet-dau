extends SceneTree
## Prints a model's node tree (non-bone), skeleton root chain and materials.
##   godot --headless --path . --script res://tools/vrm_info.gd -- res://assets/models/vrm/NgaMi.glb

func _init() -> void:
	for p in OS.get_cmdline_user_args():
		var n: Node = load(p).instantiate()
		for c in n.find_children("*", "", true, false):
			print(n.get_path_to(c), " [", c.get_class(), "]")
		for s in n.find_children("*", "Skeleton3D", true, false):
			var sk := s as Skeleton3D
			print("skeleton ", n.get_path_to(sk), " bones ", sk.get_bone_count())
			for b in ["root", "pelvis", "hand_l", "hand_r", "Head", "Root", "J_Bip_C_Hips", "J_Bip_L_Hand", "J_Bip_C_Head", "J_Bip_R_Hand", "J_Bip_R_UpperArm", "J_Bip_L_Foot", "mixamorig:Hips", "mixamorig:Head", "mixamorig:RightHand", "mixamorig:LeftFoot", "Hips", "Head"]:
				var i := sk.find_bone(b)
				if i >= 0:
					print("  ", b, " parent ", sk.get_bone_parent(i), " rest ", sk.get_bone_rest(i), " grest ", sk.get_bone_global_rest(i).origin)
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			print("mesh ", mi.name, " surfaces ", mi.mesh.get_surface_count(), " aabb ", mi.get_aabb(), " blend ", mi.get_blend_shape_count())
			for si in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(si)
				var extra := ""
				if mat is BaseMaterial3D:
					var bm := mat as BaseMaterial3D
					extra = " transp %d shading %d tex %s cull %d" % [bm.transparency, bm.shading_mode, bm.albedo_texture != null, bm.cull_mode]
				print("   ", si, " ", mat.resource_name if mat else "null", " ", mat.get_class() if mat else "", extra)
			if mi.get_blend_shape_count() > 0:
				var names := []
				for k in mi.get_blend_shape_count():
					names.append(String(mi.mesh.get_blend_shape_name(k)))
				print("   shapes ", ", ".join(names))
	quit()
