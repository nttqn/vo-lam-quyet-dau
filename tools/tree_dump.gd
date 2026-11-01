extends SceneTree
func _init() -> void:
	for p in OS.get_cmdline_user_args():
		var n: Node = load(p).instantiate()
		print("== ", p)
		_dump(n, 0)
		for ap in n.find_children("*", "AnimationPlayer", true, false):
			var a: Animation = ap.get_animation(ap.get_animation_list()[1])
			print("anim ", ap.get_animation_list()[1], " len ", a.length, " tracks ", a.get_track_count())
			for t in mini(5, a.get_track_count()):
				print("  ", a.track_get_type(t), " ", a.track_get_path(t))
	quit()
func _dump(n: Node, d: int) -> void:
	if d > 4: return
	var extra := ""
	if n is MeshInstance3D: extra = " skel=" + str(n.skeleton)
	print("  ".repeat(d), n.name, " <", n.get_class(), ">", extra)
	for c in n.get_children(): _dump(c, d + 1)
