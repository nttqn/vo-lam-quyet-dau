extends SceneTree
## Prints clip length and cumulative pelvis yaw (degrees) through a baked clip.
##   godot --headless --path . --script res://tools/spin_check.gd -- m/Hurricane_Kick [steps]

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var n: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	get_root().add_child(n)
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.add_animation_library("m", load("res://assets/models/anims/mixamo.res"))
	for clip in args[0].split(","):
		if not ap.has_animation(clip):
			print(clip, " MISSING"); continue
		ap.play(clip)
		var L := ap.current_animation_length
		var steps := int(args[1]) if args.size() > 1 else 40
		var prev := 0.0
		var total := 0.0
		var line := ""
		for i in steps + 1:
			var u := i / float(steps)
			ap.seek(L * u, true)
			var b := sk.get_bone_global_pose(sk.find_bone("pelvis")).basis
			var fwd := b.z
			var yaw := rad_to_deg(atan2(fwd.x, fwd.z))
			if i > 0:
				total += wrapf(yaw - prev, -180.0, 180.0)
			prev = yaw
			if i % (steps / 10) == 0:
				line += "%.1f:%d " % [u, int(total)]
		print("%s  len %.2fs  yaw: %s" % [clip, L, line])
	quit()
