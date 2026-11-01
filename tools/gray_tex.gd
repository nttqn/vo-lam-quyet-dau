extends SceneTree
## Makes tintable grey versions of the outfit albedo atlases.
func _init() -> void:
	for n in ["T_Peasant_BaseColor", "T_Ranger_BaseColor"]:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/models/outfits/%s.png" % n))
		img.convert(Image.FORMAT_RGBA8)
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		# luminance, then stretch so mid-tones sit near 0.75 (tints stay vivid)
		var w := img.get_width()
		var h := img.get_height()
		var lo := 1.0
		var hi := 0.0
		for y in range(0, h, 7):
			for x in range(0, w, 7):
				var c := img.get_pixel(x, y)
				if c.a < 0.5: continue
				var l := c.get_luminance()
				lo = minf(lo, l); hi = maxf(hi, l)
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var l := (c.get_luminance() - lo) / maxf(0.01, hi - lo)
				l = pow(clampf(l, 0.0, 1.0), 0.55) * 0.85 + 0.12
				img.set_pixel(x, y, Color(l, l, l, c.a))
		img.save_png(ProjectSettings.globalize_path("res://assets/models/outfits/%s_Gray.png" % n.replace("_BaseColor", "")))
		print("done ", n, " ", lo, " ", hi)
	quit()
