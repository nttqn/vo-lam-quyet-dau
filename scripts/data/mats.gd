class_name Mats
extends RefCounted
## Forge materials. The hero keeps them in h.mats = {id: count}.

const IDS := ["iron", "star", "wash", "charm"]

## id -> [name, use, colour, where to get it]
const INFO := {
	"iron": ["Huyền Thiết", "Cường hóa trang bị (+1 → +15).", Color(0.62, 0.74, 0.9),
		"Phó Bản Hắc Phong Khoáng Động, Lôi Đài, Hành Tẩu, phân giải đồ cũ"],
	"star": ["Thiên Tinh Thạch", "Thăng phẩm trang bị lên bậc cao hơn.", Color(1.0, 0.76, 0.3),
		"Phó Bản Hàn Băng Động, trùm vùng, Thủ Tháp, Lôi Đài mốc 10"],
	"wash": ["Tẩy Luyện Thạch", "Tẩy luyện lại thuộc tính phụ.", Color(0.55, 1.0, 0.7),
		"Phó Bản Độc Long Cốc, Tỉ Võ, Lôi Đài mốc 10, Tiệm (Ngọc)"],
	"charm": ["Hộ Phù", "Giữ cấp cường hóa khi thất bại.", Color(1.0, 0.5, 0.45),
		"Lôi Đài mốc 5, Tháp mỗi 5 tầng, Tiệm (Ngọc)"],
}

## Letter on the fallback gem (until painted icons exist): Thiết, sao, Luyện, Phù.
const GLYPH := {"iron": "T", "star": "★", "wash": "L", "charm": "P"}

static func name_of(id: String) -> String:
	return INFO[id][0]

static func color(id: String) -> Color:
	return INFO[id][2]

static func count(h: Dictionary, id: String) -> int:
	return int(Dictionary(h.get("mats", {})).get(id, 0))

static func add(h: Dictionary, id: String, n: int) -> void:
	if not h.has("mats") or not (h.mats is Dictionary):
		h.mats = {}
	h.mats[id] = maxi(0, count(h, id) + n)

static func spend(h: Dictionary, id: String, n: int) -> bool:
	if count(h, id) < n:
		return false
	add(h, id, -n)
	return true

static func give(h: Dictionary, rw: Dictionary) -> void:
	for id in rw:
		add(h, str(id), int(rw[id]))

## "Huyền Thiết +12 · Hộ Phù +1"
static func text(rw: Dictionary, sep := "  ·  ") -> String:
	var parts := []
	for id in IDS:
		if int(rw.get(id, 0)) > 0:
			parts.append("%s +%d" % [name_of(id), int(rw[id])])
	return sep.join(parts)

## Sum of two reward dicts.
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for id in b:
		out[id] = int(out.get(id, 0)) + int(b[id])
	return out

## Painted icon (assets/ui/mats/<id>.png) if present.
static func icon(id: String) -> Texture2D:
	var p := "res://assets/ui/mats/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else null

## Small gem + count, for wallets and cost lines. need > 0 shows "have/need"
## in red when short.
static func chip(h: Dictionary, id: String, need := -1, size := 34) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gem(id, size))
	var have := count(h, id)
	var txt := str(have) if need < 0 else "%d/%d" % [have, need]
	var col := Color(0.95, 0.92, 0.85)
	if need >= 0:
		col = Color(0.6, 1.0, 0.6) if have >= need else Color(1.0, 0.45, 0.4)
	var l := UI.label(txt, int(size * 0.62), col, UI.bold)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	row.tooltip_text = "%s — %s" % [name_of(id), INFO[id][1]]
	return row

static func gem(id: String, size := 34) -> Control:
	var tex := icon(id)
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(size, size)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return r
	# fallback: a faceted coloured disc with the first letter
	var c := color(id)
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UI.box(c.darkened(0.45), c.lightened(0.3), 2, int(size * 0.3), 0)
	st.shadow_size = 0
	p.add_theme_stylebox_override("panel", st)
	var l := UI.label(GLYPH.get(id, "?"), int(size * 0.55), c.lightened(0.5), UI.title)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p
