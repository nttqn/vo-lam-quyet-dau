extends Node3D
## Close-up lineup of appearance variants.
var shot := "user://faces.png"
var n := 0
var avs: Array = []

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
	add_child(Arena.new("temple", 2))
	var variants := [
		["vo_dang", {"female": false, "skin": 0, "hair": 0, "hair_col": 0, "eye": 0, "lip": 0, "brow": 0, "face": 0, "beard": false}],
		["vo_dang", {"female": false, "skin": 3, "hair": 2, "hair_col": 2, "eye": 2, "lip": 0, "brow": 0, "face": 2, "beard": true}],
		["nga_mi", {"female": true, "skin": 0, "hair": 1, "hair_col": 0, "eye": 1, "lip": 2, "brow": 1, "face": 1}],
		["nga_mi", {"female": true, "skin": 2, "hair": 0, "hair_col": 3, "eye": 4, "lip": 3, "brow": 1, "face": 3}],
		["cai_bang", {"female": false, "skin": 5, "hair": 3, "hair_col": 4, "eye": 3, "lip": 0, "brow": 0, "face": 4, "beard": true}],
		["thieu_lam", {"female": true, "skin": 1, "hair": 4, "hair_col": 0, "eye": 5, "lip": 1, "brow": 1, "face": 0}],
	]
	for i in variants.size():
		var lk := Appearance.apply(Sects.get_sect(variants[i][0]).look, variants[i][1])
		var av := Avatar.new(lk)
		add_child(av)
		av.position = Vector3(-2.5 + i * 1.0, 0, 0)
		avs.append(av)
	var cam := Camera3D.new()
	cam.fov = 32
	cam.position = Vector3(0, 1.62, 3.2)
	add_child(cam)
	cam.look_at(Vector3(0, 1.55, 0))

func _process(d: float) -> void:
	n += 1
	for av in avs:
		av.pose("a/Idle", 0.5, 0.0)
		av.finish(d)
	if n == 12:
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
