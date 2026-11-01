extends SceneTree
## Bakes every Mixamo FBX in res://assets_src/animation onto the game's
## UE-style rig and saves res://assets/models/anims/mixamo.res
## (clip name = file name with spaces -> underscores, e.g. "m/Mma_Kick").
##   godot --headless --path . --script res://tools/retarget_mixamo.gd

const MAP := {
	"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03",
	"Neck": "neck_01", "Head": "Head",
	"LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
	"RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
	"LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
}
const FPS := 30.0
const SRC_DIR := "res://assets_src/animation/"

func _initialize() -> void:
	await process_frame
	await _bake_all()
	quit()

static func _short(bone: String) -> String:
	var b := bone
	for pre in ["mixamorig:", "mixamorig_", "mixamorig1:", "mixamorig1_", "mixamorig2_", "mixamorig2:"]:
		if b.begins_with(pre):
			b = b.substr(pre.length())
	return b

func _bake_all() -> void:
	var dst_root: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	get_root().add_child(dst_root)
	var T: Skeleton3D = dst_root.find_children("*", "Skeleton3D", true, false)[0]
	var lib := AnimationLibrary.new()
	var dir := DirAccess.open(SRC_DIR)
	for f in dir.get_files():
		if not f.to_lower().ends_with(".fbx"):
			continue
		var src_root: Node = load(SRC_DIR + f).instantiate()
		get_root().add_child(src_root)
		await process_frame
		var S: Skeleton3D = src_root.find_children("*", "Skeleton3D", true, false)[0]
		var sap: AnimationPlayer = src_root.find_children("*", "AnimationPlayer", true, false)[0]
		var t2s := {}
		var s_hip := -1
		for si in S.get_bone_count():
			var sn := _short(S.get_bone_name(si))
			if MAP.has(sn):
				var ti := T.find_bone(MAP[sn])
				if ti >= 0:
					t2s[ti] = si
				if sn == "Hips":
					s_hip = si
		var t_hip := T.find_bone("pelvis")
		var ratio := T.get_bone_global_rest(t_hip).origin.y / maxf(0.0001, S.get_bone_global_rest(s_hip).origin.y)
		var clips := sap.get_animation_list()
		var an: String = clips[0]
		for c in clips:
			if c != "RESET":
				an = c
		var a_src: Animation = sap.get_animation(an)
		var out := Animation.new()
		out.length = a_src.length
		var tpath := "Armature/Skeleton3D"
		var rot_tracks := {}
		for ti in t2s:
			var tr := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(tr, NodePath(tpath + ":" + T.get_bone_name(ti)))
			rot_tracks[ti] = tr
		var pos_tr := out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(pos_tr, NodePath(tpath + ":pelvis"))
		var frames := int(ceil(a_src.length * FPS))
		sap.play(an)
		var hip0 := Vector3.ZERO
		for fi in frames + 1:
			var t := minf(a_src.length, fi / FPS)
			sap.seek(t, true)
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
					local.basis = (pg.basis.orthonormalized().inverse() * gt).orthonormalized()
					out.rotation_track_insert_key(rot_tracks[ti], t, local.basis.get_rotation_quaternion())
				tg[ti] = pg * local
			# hips: keep the vertical bob, drop horizontal drift (the sim moves the fighter)
			var sh := S.get_bone_global_pose(s_hip).origin - S.get_bone_global_rest(s_hip).origin
			if fi == 0:
				hip0 = sh
			sh = Vector3(0, sh.y, 0)
			var parent_t := T.get_bone_parent(t_hip)
			var pgb: Basis = Basis.IDENTITY if parent_t < 0 else (tg[parent_t] as Transform3D).basis.orthonormalized()
			out.position_track_insert_key(pos_tr, t, T.get_bone_rest(t_hip).origin + pgb.inverse() * (sh * ratio))
		var name := f.get_basename().replace(" ", "_")
		lib.add_animation(name, out)
		print("baked ", name, " (", an, ") ", frames, " frames, ", t2s.size(), " bones, len ", a_src.length)
		src_root.queue_free()
	ResourceSaver.save(lib, "res://assets/models/anims/mixamo.res")
	print("saved mixamo.res")
