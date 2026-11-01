extends Node3D
## Lineup of imported CC0 models posed with UAL2 animations, screenshot + quit.

var shot := "user://models.png"
var n := 0
var anim := "Sword_Regular_A"
var at := 0.35

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
		if a.begins_with("--anim="): anim = a.substr(7)
		if a.begins_with("--at="): at = float(a.substr(5))
	add_child(Arena.new("temple", 2))
	var ual: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
	var lib: AnimationLibrary = (ual.get_node("AnimationPlayer") as AnimationPlayer).get_animation_library("")
	var outfits := ["Male_Peasant", "Male_Ranger", "Female_Peasant", "Female_Ranger"]
	for i in outfits.size():
		var root: Node3D = load("res://assets/models/outfits/%s.gltf" % outfits[i]).instantiate()
		add_child(root)
		root.position = Vector3(-3.0 + i * 2.0, 0, 0)
		root.rotation.y = 0.4
		var skel: Skeleton3D = root.get_node("Armature/Skeleton3D")
		var hair := "Hair_Buns" if i % 2 == 0 else "Hair_Long"
		for extra in ["res://assets/models/hair/%s.gltf" % hair]:
			var h: Node = load(extra).instantiate()
			for m in h.find_children("*", "MeshInstance3D", true, false):
				m.get_parent().remove_child(m)
				skel.add_child(m)
				m.skeleton = NodePath("..")
		var ap := AnimationPlayer.new()
		root.add_child(ap)
		ap.add_animation_library("", lib)
		ap.play(anim)
		ap.seek(at, true)
		ap.pause()
	var cam := Camera3D.new()
	cam.fov = 40
	cam.position = Vector3(0, 1.3, 6.5)
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0))

func _process(_d: float) -> void:
	n += 1
	if n == 10:
		get_viewport().get_texture().get_image().save_png(shot)
		print("shot ", shot)
		get_tree().quit()
