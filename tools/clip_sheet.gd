extends Node3D
## Grid of avatars each frozen in a clip at a fraction of its length.
##   --clips=a/Idle,b/Sword_Block  --frac=0.5  --sect=vo_dang  --shot=out.png

var shot := "user://clips.png"
var n := 0
var avs: Array = []
var clips: PackedStringArray
var frac := 0.5
var fracs: PackedStringArray = []

func _ready() -> void:
	var sect := "vo_dang"
	clips = PackedStringArray(["a/Idle", "a/Walk", "a/Punch_Jab", "a/Punch_Cross", "b/Sword_Regular_A", "b/Sword_Block", "a/Hit_Chest", "b/Hit_Knockback"])
	var cols := 4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
		if a.begins_with("--clips="): clips = a.substr(8).split(",")
		if a.begins_with("--frac="): frac = float(a.substr(7))
		if a.begins_with("--fracs="): fracs = a.substr(8).split(",")
		if a.begins_with("--sect="): sect = a.substr(7)
		if a.begins_with("--cols="): cols = int(a.substr(7))
	add_child(Arena.new("temple", 2))
	var lk: Dictionary = Sects.get_sect(sect).look.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--grip="):
			var p := a.substr(7).split(":")
			lk["grip_rot"] = Vector3(float(p[0]), float(p[1]), float(p[2]))
	var rows := int(ceil(clips.size() / float(cols)))
	for i in clips.size():
		var lki := lk
		if "--allsects" in OS.get_cmdline_user_args():
			lki = Sects.get_sect(Sects.IDS[i % 5]).look
		var av := Avatar.new(lki)
		add_child(av)
		av.position = Vector3((i % cols - (cols - 1) * 0.5) * 2.2, 0, -(i / cols) * 2.6)
		av.rotation.y = PI * 0.5 - 0.35
		avs.append(av)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--ov="):
				var specs := a.substr(5).split(";")
				if i < specs.size() and specs[i] != "":
					for sp in specs[i].split("+"):
						var q := sp.split(":")
						av.overrides[q[0]] = Quaternion.from_euler(Vector3(float(q[1]), float(q[2]), float(q[3])) * PI / 180.0)
		var l := Label3D.new()
		l.text = clips[i] + " " + str(i)
		l.font_size = 40
		l.outline_size = 8
		l.position = av.position + Vector3(0, 2.15, 0)
		add_child(l)
	var cam := Camera3D.new()
	cam.fov = 42
	cam.position = Vector3(0, 1.8 + rows * 0.6, 5.5 + rows * 1.6)
	add_child(cam)
	cam.look_at(Vector3(0, 0.9, -(rows - 1) * 1.3))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cam="):
			var c := a.substr(6).split(",")
			cam.position = Vector3(float(c[0]), float(c[1]), float(c[2]))
			cam.look_at(Vector3(0, float(c[3]), 0))

func _process(d: float) -> void:
	n += 1
	for i in avs.size():
		var av: Avatar = avs[i]
		var fq := float(fracs[i]) if i < fracs.size() else frac
		av.pose(clips[i], av.clip_len(clips[i]) * fq, 0.0)
		av.finish(d)
	if n == 12:
		get_viewport().get_texture().get_image().save_png(shot)
		print("shot ", shot)
		get_tree().quit()
