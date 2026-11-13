extends Node3D
## How far each sect model's soles are from the ground (y 0) in its idle stance.
## Negative = sinking.  godot --headless --path . -- --feetprobe
const SECTS := ["thieu_lam", "vo_dang", "nga_mi", "cai_bang", "duong_mon"]

func _ready() -> void:
	for s in SECTS:
		var lk: Dictionary = Sects.get_sect(s).look.duplicate()
		var b := Avatar.new(lk)
		add_child(b)
		for k in 3:
			await get_tree().process_frame
		var ic := AnimMap.idle_clip(Sects.get_sect(s).style)
		b.pose(ic[0], 0.5, 0.0)
		b.finish(0.016)
		b.finish(0.016)
		await get_tree().process_frame
		print("%-10s %s" % [s, _soles(b)])
		b.queue_free()
	get_tree().quit()

static func _soles(b: Avatar) -> String:
	var sk: Skeleton3D = b.vskel
	var low := 1e9
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.skin == null and m3.skeleton == NodePath():
			continue
		var bb: AABB = m3.global_transform * m3.get_aabb()
		low = minf(low, bb.position.y)
	var out := "rest-mesh-bottom=%.3f" % low
	for bn in ["LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]:
		var bi := -1
		for pre in ["mixamorig_", "mixamorig:", "mixamorig1_", ""]:
			bi = sk.find_bone(pre + bn)
			if bi >= 0:
				break
		if bi < 0:
			continue
		var rest_y := (sk.global_transform * sk.get_bone_global_rest(bi).origin).y
		var now_y := (sk.global_transform * sk.get_bone_global_pose(bi).origin).y
		out += "  %s rest %.3f now %.3f (sole %.3f)" % [bn, rest_y, now_y, now_y - (rest_y - low)]
	return out
