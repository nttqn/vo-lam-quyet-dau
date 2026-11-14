extends SceneTree
## Cuts ChatGPT icon sheets (transparent background, icons in rows, reading
## order) from assets_src/skills/ and assets_src/items/ into 256-square PNGs.
##   skills: <sect>.png        -> assets/ui/skills/<sect>_<0..5>.png   (3 + 3)
##   menu: menu_1.png / menu_2.png -> assets/ui/menu/<name>.png (3+3, 4+4)
##   weapons: weapon_<style>.png -> assets/ui/items/weapon_<style>_<1..7>.png (4 + 3)
##   godot --headless --path . --script res://tools/icon_cut.gd [-- thieu_lam]

## sheet -> [source, output pattern (%d = index), count, icons per row, first index]
const SHEETS := {
	"thieu_lam": ["res://assets_src/skills/thieu_lam.png", "res://assets/ui/skills/thieu_lam_%d.png", 6, [3, 3], 0],
	"vo_dang": ["res://assets_src/skills/vo_dang.png", "res://assets/ui/skills/vo_dang_%d.png", 6, [3, 3], 0],
	"nga_mi": ["res://assets_src/skills/nga_mi.png", "res://assets/ui/skills/nga_mi_%d.png", 6, [3, 3], 0],
	"cai_bang": ["res://assets_src/skills/cai_bang.png", "res://assets/ui/skills/cai_bang_%d.png", 6, [3, 3], 0],
	"duong_mon": ["res://assets_src/skills/duong_mon.png", "res://assets/ui/skills/duong_mon_%d.png", 6, [3, 3], 0],
	"vovinam": ["res://assets_src/skills/vovinam.png", "res://assets/ui/skills/vovinam_%d.png", 6, [3, 3], 0],
	"weapon_staff": ["res://assets_src/items/weapon_staff.png", "res://assets/ui/items/weapon_staff_%d.png", 7, [4, 3], 1],
	"weapon_sword": ["res://assets_src/items/weapon_sword.png", "res://assets/ui/items/weapon_sword_%d.png", 7, [4, 3], 1],
	"weapon_dual": ["res://assets_src/items/weapon_dual.png", "res://assets/ui/items/weapon_dual_%d.png", 7, [4, 3], 1],
	"weapon_palm": ["res://assets_src/items/weapon_palm.png", "res://assets/ui/items/weapon_palm_%d.png", 7, [4, 3], 1],
	"weapon_dagger": ["res://assets_src/items/weapon_dagger.png", "res://assets/ui/items/weapon_dagger_%d.png", 7, [4, 3], 1],
	"menu_1": ["res://assets_src/menu/menu_1.png", ["journey", "duel", "tower", "arena", "train", "rank"], 6, [3, 3], 0],
	"menu_2": ["res://assets_src/menu/menu_2.png", ["hero", "skill", "gear", "shop", "outfit", "quest", "settings", "exit"], 8, [4, 4], 0],
	"armor": ["res://assets_src/items/armor.png", "res://assets/ui/items/armor_%d.png", 7, [4, 3], 1],
	"hat": ["res://assets_src/items/hat.png", "res://assets/ui/items/hat_%d.png", 7, [4, 3], 1],
	"boots": ["res://assets_src/items/boots.png", "res://assets/ui/items/boots_%d.png", 7, [4, 3], 1],
	"jade": ["res://assets_src/items/jade.png", "res://assets/ui/items/jade_%d.png", 7, [4, 3], 1],
}
const SIZE := 256

func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for s in SHEETS:
		if not only.is_empty() and not s in only:
			continue
		var job: Array = SHEETS[s]
		var p := ProjectSettings.globalize_path(job[0])
		if not FileAccess.file_exists(p):
			print("missing ", s)
			continue
		var pat = job[1]
		if pat is Array:
			var names: Array = pat
			pat = names.map(func(n): return "res://assets/ui/menu/%s.png" % n)
		var first_out: String = pat[0] if pat is Array else String(pat)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(first_out.get_base_dir()))
		var img := Image.load_from_file(p)
		img.convert(Image.FORMAT_RGBA8)
		print(s, ": ", _cut(img, pat, int(job[2]), job[3], int(job[4])))
	quit()

func _cut(img: Image, out_pat: Variant, N: int, rows: Array, first: int) -> String:
	var w := img.get_width()
	var h := img.get_height()
	# A painted checkerboard / white instead of real transparency: clear the
	# pale grey reaching in from the edges.
	var corners := [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]
	var opaque := true
	for c in corners:
		if img.get_pixelv(c).a < 0.98:
			opaque = false
	if opaque:
		var seen := PackedByteArray()
		seen.resize(w * h)
		var st: Array[int] = []
		for x in w:
			st.append(x)
			st.append((h - 1) * w + x)
		for y in h:
			st.append(y * w)
			st.append(y * w + w - 1)
		while not st.is_empty():
			var i: int = st.pop_back()
			if seen[i]:
				continue
			var x := i % w
			var y := i / w
			var c := img.get_pixel(x, y)
			var mn := minf(c.r, minf(c.g, c.b))
			var mx := maxf(c.r, maxf(c.g, c.b))
			if not (mn > 0.8 and mx - mn < 0.1):
				continue
			seen[i] = 1
			img.set_pixel(x, y, Color(0, 0, 0, 0))
			if x > 0: st.append(i - 1)
			if x < w - 1: st.append(i + 1)
			if y > 0: st.append(i - w)
			if y < h - 1: st.append(i + w)
	# Soft fringe trim (same curve as Kiếm Hiệp's tool).
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var a := c.a * 255.0
			c.a = 0.0 if a <= 110.0 else (1.0 if a >= 235.0 else (a - 110.0) / 125.0)
			img.set_pixel(x, y, c)
	# Blobs on a quarter-size mask; the N biggest are the icons.
	var k := 4
	var mw := ceili(w / float(k))
	var mh := ceili(h / float(k))
	var mask := PackedByteArray()
	mask.resize(mw * mh)
	for y in range(0, h, k):
		for x in range(0, w, k):
			if img.get_pixel(x, y).a > 0.8:
				mask[(y / k) * mw + x / k] = 1
	var label := PackedInt32Array()
	label.resize(mw * mh)
	label.fill(-1)
	var blobs: Array = []
	for i in mw * mh:
		if mask[i] == 0 or label[i] >= 0:
			continue
		var b := {"n": 0, "x0": mw, "y0": mh, "x1": 0, "y1": 0}
		var st2: Array[int] = [i]
		label[i] = blobs.size()
		while not st2.is_empty():
			var j: int = st2.pop_back()
			var x := j % mw
			var y := j / mw
			b.n += 1
			b.x0 = mini(b.x0, x); b.x1 = maxi(b.x1, x); b.y0 = mini(b.y0, y); b.y1 = maxi(b.y1, y)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var xx: int = x + d.x
				var yy: int = y + d.y
				if xx < 0 or yy < 0 or xx >= mw or yy >= mh:
					continue
				var q := yy * mw + xx
				if mask[q] == 1 and label[q] < 0:
					label[q] = blobs.size()
					st2.append(q)
		blobs.append(b)
	blobs.sort_custom(func(a, b): return a.n > b.n)
	if blobs.size() < N:
		return "only %d icons found" % blobs.size()
	var icons: Array = blobs.slice(0, N)
	# reading order: rows by height (sizes from `rows`), each row left to right
	icons.sort_custom(func(a, b): return a.y0 + a.y1 < b.y0 + b.y1)
	var ordered: Array = []
	var at := 0
	for n in rows:
		var row: Array = icons.slice(at, at + int(n))
		row.sort_custom(func(a, b): return a.x0 < b.x0)
		ordered.append_array(row)
		at += int(n)
	icons = ordered
	var sizes := []
	for i in N:
		var b: Dictionary = icons[i]
		var r := Rect2i(b.x0 * k, b.y0 * k, (b.x1 - b.x0 + 1) * k, (b.y1 - b.y0 + 1) * k).grow(k * 2).intersection(Rect2i(0, 0, w, h))
		var part := img.get_region(r)
		var side := maxi(r.size.x, r.size.y)
		var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
		sq.fill(Color(0, 0, 0, 0))
		sq.blit_rect(part, Rect2i(Vector2i.ZERO, r.size), Vector2i((side - r.size.x) / 2, (side - r.size.y) / 2))
		sq.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		var out: String = out_pat[i] if out_pat is Array else String(out_pat) % (i + first)
		sq.save_png(ProjectSettings.globalize_path(out))
		sizes.append(side)
	return "ok, icon sizes %s" % [sizes]
