extends SceneTree
## Lists every bone (index, name, parent, global rest origin) of a model.
##   godot --headless --path . --script res://tools/bone_list.gd -- res://path/model.fbx

func _init() -> void:
	var n: Node = load(OS.get_cmdline_user_args()[0]).instantiate()
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	for i in sk.get_bone_count():
		print(i, " ", sk.get_bone_name(i), " p", sk.get_bone_parent(i), " ", sk.get_bone_global_rest(i).origin.snapped(Vector3.ONE * 0.001), " ", sk.get_bone_global_rest(i).basis.get_euler().snapped(Vector3.ONE * 0.01))
	var p := sk.get_parent()
	print("skeleton parent ", p.name, " xform ", (p as Node3D).transform if p is Node3D else "")
	n.free()
	quit()
