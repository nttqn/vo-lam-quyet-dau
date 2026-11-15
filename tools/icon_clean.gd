extends SceneTree
## Removes stray fragments of neighbouring icons from cut icons: any opaque
## blob that touches the image border and is much smaller than the biggest
## blob is erased.
##   godot --headless --path . --script res://tools/icon_clean.gd -- res://assets/ui/items/jade_1.png ...

func _init() -> void:
	for p in OS.get_cmdline_user_args():
		var img := Image.load_from_file(p)
		if img == null:
			print("cannot load ", p)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var n := _clean(img)
		img.save_png(ProjectSettings.globalize_path(p))
		print("%s: removed %d px" % [p, n])
	quit()

func _clean(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var lab := PackedInt32Array()
	lab.resize(w * h)
	lab.fill(0)
	var sizes := [0]
	var border := [false]
	var next := 1
	for y in h:
		for x in w:
			var i := y * w + x
			if lab[i] != 0 or img.get_pixel(x, y).a < 0.04:
				continue
			# flood fill, 8-connected
			var stack := [i]
			lab[i] = next
			var cnt := 0
			var edge := false
			while not stack.is_empty():
				var j: int = stack.pop_back()
				cnt += 1
				var jx := j % w
				var jy := j / w
				if jx == 0 or jy == 0 or jx == w - 1 or jy == h - 1:
					edge = true
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var nx: int = jx + dx
						var ny: int = jy + dy
						if nx < 0 or ny < 0 or nx >= w or ny >= h:
							continue
						var k := ny * w + nx
						if lab[k] == 0 and img.get_pixel(nx, ny).a >= 0.04:
							lab[k] = next
							stack.append(k)
			sizes.append(cnt)
			border.append(edge)
			next += 1
	var big := 0
	for s in sizes:
		big = maxi(big, s)
	var removed := 0
	for y in h:
		for x in w:
			var l := lab[y * w + x]
			if l > 0 and border[l] and sizes[l] < big * 0.08:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				removed += 1
	return removed
