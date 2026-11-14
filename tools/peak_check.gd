extends SceneTree
## Strike timing per clip: forward reach (z, metres in front of the hips) of the
## furthest hand and foot, sampled through the clip, plus local reach peaks.
##   godot --headless --path . --script res://tools/peak_check.gd -- m/A,m/B [steps]

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var n: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	get_root().add_child(n)
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.add_animation_library("m", load("res://assets/models/anims/mixamo.res"))
	var steps := int(args[1]) if args.size() > 1 else 40
	for clip in args[0].split(","):
		ap.play(clip)
		var L := ap.current_animation_length
		var hz := []
		var fz := []
		var fy := []
		var hy := []
		for i in steps + 1:
			ap.seek(L * i / float(steps), true)
			var p := func(b: String) -> Vector3: return sk.get_bone_global_pose(sk.find_bone(b)).origin
			var hip: Vector3 = p.call("pelvis")
			var hr: Vector3 = p.call("hand_r"); var hl: Vector3 = p.call("hand_l")
			var fr: Vector3 = p.call("foot_r"); var fl: Vector3 = p.call("foot_l")
			hz.append(maxf(hr.z, hl.z) - hip.z)
			hy.append(maxf(hr.y, hl.y))
			fz.append(maxf(fr.z, fl.z) - hip.z)
			fy.append(maxf(fr.y, fl.y))
		var s := "%s len %.2f\n  hand z:" % [clip, L]
		for i in range(0, steps + 1, 2): s += " %d" % int(hz[i] * 100)
		s += "\n  hand y:"
		for i in range(0, steps + 1, 2): s += " %d" % int(hy[i] * 100)
		s += "\n  foot z:"
		for i in range(0, steps + 1, 2): s += " %d" % int(fz[i] * 100)
		s += "\n  foot y:"
		for i in range(0, steps + 1, 2): s += " %d" % int(fy[i] * 100)
		var pk := "\n  hand peaks:"
		for i in range(1, steps):
			if hz[i] >= hz[i - 1] and hz[i] > hz[i + 1] and hz[i] > 0.35: pk += " %.3f(%d)" % [i / float(steps), int(hz[i] * 100)]
		pk += "\n  foot peaks:"
		for i in range(1, steps):
			if fz[i] >= fz[i - 1] and fz[i] > fz[i + 1] and fz[i] > 0.3: pk += " %.3f(%d,y%d)" % [i / float(steps), int(fz[i] * 100), int(fy[i] * 100)]
		print(s + pk)
	quit()
