class_name Outfits
extends RefCounted
## Y phục: premium outfits, one extra model per outfit
## (assets/models/chars/<SectModel>_<Id>.fbx, made like the base sect models).
## An outfit whose model file is not in the game yet shows as "coming soon".
## h.outfits = [owned ids], h.outfit = worn id ("" = the sect's own clothes).

const LIST := {
	"thieu_lam": [{"id": "KimCang", "name": "Kim Cang", "price": 300, "desc": "Áo vàng viền đỏ, rồng vàng thêu sau lưng, chuỗi hạt vàng."}],
	"vo_dang": [{"id": "ThaiCuc", "name": "Thái Cực", "price": 300, "desc": "Lụa trắng viền lam đậm, mây bạc, âm dương lớn sau lưng."}],
	"nga_mi": [{"id": "PhuongHoang", "name": "Phượng Hoàng", "price": 300, "desc": "Trắng và đỏ thẫm, phượng vàng thêu sau lưng, trâm phượng."}],
	"cai_bang": [{"id": "LongBang", "name": "Long Bang", "price": 300, "desc": "Áo xanh rêu vá chỉ vàng, hồ lô đồng, băng đầu đỏ."}],
	"duong_mon": [{"id": "AmAnh", "name": "Ám Ảnh", "price": 300, "desc": "Đen và tím thẫm viền bạc, đai phi đao, bao tay thép."}],
}

static func of(sect_id: String) -> Array:
	return LIST.get(sect_id, [])

static func model_name(sect_id: String, id: String) -> String:
	var base := str(Sects.get_sect(sect_id).look.get("model", ""))
	return base + "_" + id if base != "" and id != "" else base

static func available(sect_id: String, id: String) -> bool:
	return Avatar.model_path(model_name(sect_id, id)) != ""

static func owned(h: Dictionary, id: String) -> bool:
	return id in h.get("outfits", [])

## Model to use for a hero wearing `id` (falls back to the sect model).
static func model_for(sect_id: String, id: String) -> String:
	if id != "" and available(sect_id, id):
		return model_name(sect_id, id)
	return str(Sects.get_sect(sect_id).look.get("model", ""))
