extends SceneTree
## Bakes UAL1 (Rigify DEF-* rig) animations onto the UE-style rig used by the
## Quaternius characters and UAL2, saving res://assets/models/anims/ual1_ue.res
##   godot --headless --path . --script res://tools/retarget.gd

const MAP := {
	"DEF-hips": "pelvis", "DEF-spine.001": "spine_01", "DEF-spine.002": "spine_02", "DEF-spine.003": "spine_03",
	"DEF-neck": "neck_01", "DEF-head": "Head",
	"DEF-shoulder.L": "clavicle_l", "DEF-upper_arm.L": "upperarm_l", "DEF-forearm.L": "lowerarm_l", "DEF-hand.L": "hand_l",
	"DEF-shoulder.R": "clavicle_r", "DEF-upper_arm.R": "upperarm_r", "DEF-forearm.R": "lowerarm_r", "DEF-hand.R": "hand_r",
	"DEF-thigh.L": "thigh_l", "DEF-shin.L": "calf_l", "DEF-foot.L": "foot_l", "DEF-toe.L": "ball_l",
	"DEF-thigh.R": "thigh_r", "DEF-shin.R": "calf_r", "DEF-foot.R": "foot_r", "DEF-toe.R": "ball_r",
}
const FPS := 30.0

func _initialize() -> void:
	await process_frame
	_bake()

func _bake() -> void:
	var src_root: Node = load("res://assets/models/anims/UAL1_Standard.glb").instantiate()
	var dst_root: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	get_root().add_child(src_root)
	get_root().add_child(dst_root)
	var S: Skeleton3D = src_root.find_children("*", "Skeleton3D", true, false)[0]
	var T: Skeleton3D = dst_root.find_children("*", "Skeleton3D", true, false)[0]
	var sap: AnimationPlayer = src_root.find_children("*", "AnimationPlayer", true, false)[0]
	var tpath := "Armature/Skeleton3D"
	# map target bone -> source bone index
	var t2s := {}
	for sname in MAP:
		var si := S.find_bone(sname)
		var ti := T.find_bone(MAP[sname])
		if si >= 0 and ti >= 0:
			t2s[ti] = si
		else:
			print("missing ", sname, " ", si, " ", ti)
	var s_hip := S.find_bone("DEF-hips")
	var t_hip := T.find_bone("pelvis")
	var ratio := T.get_bone_global_rest(t_hip).origin.y / maxf(0.001, S.get_bone_global_rest(s_hip).origin.y)
	print("hip ratio ", ratio)
	var lib := AnimationLibrary.new()
	var wanted := ["Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Crouch_Idle_Loop", "Crouch_Fwd_Loop", "Punch_Jab", "Punch_Cross", "Punch_Enter",
		"Hit_Chest", "Hit_Head", "Death01", "Jump_Start", "Jump_Loop", "Jump_Land", "Roll", "Spell_Simple_Shoot", "Spell_Simple_Enter",
		"Sword_Attack", "Sword_Idle", "Dance_Loop", "Sprint_Loop", "Push_Loop", "Interact", "PickUp_Table"]
	for an in wanted:
		if not sap.has_animation(an) and sap.has_animation(an.replace("_Loop", "")):
			an = an.replace("_Loop", "")
		if not sap.has_animation(an):
			print("no anim ", an)
			continue
		var a_src: Animation = sap.get_animation(an)
		var out := Animation.new()
		out.length = a_src.length
		out.loop_mode = a_src.loop_mode if a_src.loop_mode != Animation.LOOP_NONE or an != "Sword_Idle" else Animation.LOOP_LINEAR
		var rot_tracks := {}
		for ti in t2s:
			var tr := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(tr, NodePath(tpath + ":" + T.get_bone_name(ti)))
			rot_tracks[ti] = tr
		var pos_tr := out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(pos_tr, NodePath(tpath + ":pelvis"))
		var frames := int(ceil(a_src.length * FPS))
		sap.play(an)
		for f in frames + 1:
			var t := minf(a_src.length, f / FPS)
			sap.seek(t, true)
			# target globals, walking the hierarchy in index order (parents first)
			var tg := []
			tg.resize(T.get_bone_count())
			for ti in T.get_bone_count():
				var parent := T.get_bone_parent(ti)
				var pg: Transform3D = Transform3D.IDENTITY if parent < 0 else tg[parent]
				var local := T.get_bone_rest(ti)
				if t2s.has(ti):
					var si: int = t2s[ti]
					var gs := S.get_bone_global_pose(si).basis.orthonormalized()
					var rs := S.get_bone_global_rest(si).basis.orthonormalized()
					var rt := T.get_bone_global_rest(ti).basis.orthonormalized()
					var gt := (gs * rs.inverse()) * rt
					var lb := pg.basis.orthonormalized().inverse() * gt
					local.basis = lb.orthonormalized()
					out.rotation_track_insert_key(rot_tracks[ti], t, local.basis.get_rotation_quaternion())
				tg[ti] = pg * local
			# pelvis translation: source hip offset from rest, scaled
			var sh := S.get_bone_global_pose(s_hip).origin - S.get_bone_global_rest(s_hip).origin
			var parent_t := T.get_bone_parent(t_hip)
			var pgb: Basis = Basis.IDENTITY if parent_t < 0 else (tg[parent_t] as Transform3D).basis.orthonormalized()
			var pos := T.get_bone_rest(t_hip).origin + pgb.inverse() * (sh * ratio)
			out.position_track_insert_key(pos_tr, t, pos)
		lib.add_animation(an, out)
		print("baked ", an, " ", frames, " frames")
	ResourceSaver.save(lib, "res://assets/models/anims/ual1_ue.res")
	print("saved")
	quit()
