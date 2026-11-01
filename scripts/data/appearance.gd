class_name Appearance
extends RefCounted
## Character creation options (stored in hero.appearance as indices).

const SKIN := [Color(0.98, 0.84, 0.72), Color(0.93, 0.76, 0.62), Color(0.86, 0.66, 0.5), Color(0.74, 0.54, 0.38), Color(0.58, 0.4, 0.28), Color(0.42, 0.28, 0.2)]
const SKIN_NAMES := ["Trắng hồng", "Trắng ngà", "Bánh mật", "Ngăm", "Nâu", "Đen"]
const HAIR_COL := [Color(0.06, 0.05, 0.05), Color(0.2, 0.12, 0.07), Color(0.38, 0.2, 0.1), Color(0.55, 0.12, 0.08), Color(0.72, 0.72, 0.74), Color(0.62, 0.5, 0.3)]
const HAIR_COL_NAMES := ["Đen", "Nâu đen", "Hạt dẻ", "Đỏ son", "Bạc", "Vàng rơm"]
const EYE := [Color(0.12, 0.07, 0.04), Color(0.38, 0.22, 0.1), Color(0.7, 0.45, 0.1), Color(0.35, 0.42, 0.45), Color(0.2, 0.45, 0.75), Color(0.6, 0.15, 0.15)]
const EYE_NAMES := ["Đen", "Nâu", "Hổ phách", "Xám", "Lam", "Huyết"]
const LIP := [Color(0.0, 0, 0), Color(0.72, 0.42, 0.38), Color(0.78, 0.25, 0.25), Color(0.65, 0.12, 0.2), Color(0.55, 0.3, 0.3), Color(0.35, 0.2, 0.22)]
const LIP_NAMES := ["Tự nhiên", "Hồng nhạt", "Đỏ", "Đỏ thắm", "Trầm", "Tím sẫm"]
const HAIR_M := ["bun", "long", "headband", "buzz", "bald"]
const HAIR_F := ["bun", "long", "headband", "buzz", "bald"]
const HAIR_NAMES := {"bun": "Búi tóc", "long": "Tóc dài", "headband": "Rẽ ngôi", "buzz": "Cắt ngắn", "bald": "Cạo trọc"}
const BROW_NAMES := ["Mày rậm", "Mày thanh"]
const FACE_NAMES := ["Cân đối", "Thon", "Vuông", "Tròn", "Dài"]
# Head bone scale per face preset (x = width, y = length along the neck, z = depth)
const FACE_SCALE := [Vector3(1, 1, 1), Vector3(0.93, 1.03, 0.97), Vector3(1.07, 0.97, 1.02), Vector3(1.06, 0.95, 1.06), Vector3(0.95, 1.08, 0.98)]
const HEIGHT_NAMES := ["Thấp", "Vừa", "Cao"]
const HEIGHT := [0.94, 1.0, 1.05]

static func default_for(sect_id: String, female: bool) -> Dictionary:
	var a := {"female": female, "skin": 1, "hair": 0, "hair_col": 0, "eye": 0, "lip": 1 if female else 0,
		"brow": 1 if female else 0, "face": 0, "beard": false, "height": 1}
	match sect_id:
		"thieu_lam": a.hair = HAIR_M.find("bald")
		"nga_mi": a.hair = HAIR_F.find("long")
		"cai_bang":
			a.hair = HAIR_M.find("headband")
			a.beard = not female
		"duong_mon": a.hair = HAIR_M.find("buzz")
	return a

static func hair_list(female: bool) -> Array:
	return HAIR_F if female else HAIR_M

## Merge appearance into a sect look dictionary.
static func apply(look: Dictionary, a: Dictionary) -> Dictionary:
	var lk := look.duplicate()
	if a.is_empty():
		return lk
	var female: bool = a.get("female", false)
	lk.female = female
	lk.skin_tone = SKIN[clampi(int(a.get("skin", 1)), 0, SKIN.size() - 1)]
	lk.hair = HAIR_COL[clampi(int(a.get("hair_col", 0)), 0, HAIR_COL.size() - 1)]
	lk.eye = EYE[clampi(int(a.get("eye", 0)), 0, EYE.size() - 1)]
	var li := clampi(int(a.get("lip", 0)), 0, LIP.size() - 1)
	lk.lip = LIP[li]
	lk.lip_amt = 0.0 if li == 0 else 0.85
	lk.brow = int(a.get("brow", 0))
	lk.face = clampi(int(a.get("face", 0)), 0, FACE_SCALE.size() - 1)
	lk.height = HEIGHT[clampi(int(a.get("height", 1)), 0, 2)]
	var hl := hair_list(female)
	var hs: String = hl[clampi(int(a.get("hair", 0)), 0, hl.size() - 1)]
	lk.acc = look.get("head_style", "")
	lk.hair_style = hs
	lk.beard = a.get("beard", false) and not female
	return lk
