extends SceneTree
## Shrinks Meshy GLBs for the phone: keeps the colour texture (resized to
## --max px), drops normal / metallic-roughness / occlusion maps, writes a new GLB.
##   godot --headless --path . --script res://tools/slim_glb.gd -- --max=512 in.glb out.glb [in2 out2 ...]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mx := 512
	var files: Array = []
	for a in args:
		if a.begins_with("--max="):
			mx = int(a.substr(6))
		else:
			files.append(a)
	for i in range(0, files.size() - 1, 2):
		print(String(files[i]).get_file(), " -> ", _slim(files[i], files[i + 1], mx))
	quit()

func _slim(src: String, dst: String, mx: int) -> String:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(src, st)
	if err != OK:
		return "load failed %d" % err
	var scene: Node = doc.generate_scene(st)
	var done := {}
	var sizes := []
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		for s in m3.mesh.get_surface_count():
			var mat = m3.get_surface_override_material(s)
			if mat == null:
				mat = m3.mesh.surface_get_material(s)
			if not mat is BaseMaterial3D:
				continue
			var bm := mat as BaseMaterial3D
			if done.has(bm):
				continue
			done[bm] = true
			bm.normal_enabled = false
			bm.normal_texture = null
			bm.metallic_texture = null
			bm.roughness_texture = null
			bm.ao_enabled = false
			bm.ao_texture = null
			bm.metallic = 0.0
			bm.roughness = 0.9
			if bm.albedo_texture:
				var img: Image = bm.albedo_texture.get_image()
				if img.is_compressed():
					img.decompress()
				if img.get_width() > mx or img.get_height() > mx:
					var k := float(mx) / maxf(img.get_width(), img.get_height())
					img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
				sizes.append(img.get_width())
				bm.albedo_texture = ImageTexture.create_from_image(img)
	var doc2 := GLTFDocument.new()
	var st2 := GLTFState.new()
	err = doc2.append_from_scene(scene, st2)
	if err != OK:
		scene.free()
		return "rebuild failed %d" % err
	err = doc2.write_to_filesystem(st2, dst)
	scene.free()
	if err != OK:
		return "write failed %d" % err
	return "ok, textures %s, %.1f MB" % [sizes, FileAccess.get_file_as_bytes(dst).size() / 1048576.0]
