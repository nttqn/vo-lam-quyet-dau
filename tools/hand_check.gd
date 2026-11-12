extends SceneTree
## Prints hand height / forward reach through a baked clip (when the strike lands).
##   godot --headless --path . --script res://tools/foot_check.gd -- m/Front_Kick

func _initialize() -> void:
	await process_frame
	var clip: String = OS.get_cmdline_user_args()[0]
	var n: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	get_root().add_child(n)
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.add_animation_library("m", load("res://assets/models/anims/mixamo.res"))
	ap.play(clip)
	var L := ap.current_animation_length
	var steps := int(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else 20
	var a0 := float(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else 0.0
	var a1 := float(OS.get_cmdline_user_args()[3]) if OS.get_cmdline_user_args().size() > 3 else 1.0
	for i in steps + 1:
		var u := lerpf(a0, a1, i / float(steps))
		ap.seek(L * u, true)
		var fl := sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
		var fr := sk.get_bone_global_pose(sk.find_bone("hand_r")).origin
		var hp := sk.get_bone_global_pose(sk.find_bone("pelvis")).origin
		print("%.2f  L y%.2f z%.2f   R y%.2f z%.2f   hip y%.2f z%.2f x%.2f" % [u, fl.y, fl.z, fr.y, fr.z, hp.y, hp.z, hp.x])
	quit()
