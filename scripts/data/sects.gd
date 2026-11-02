class_name Sects
extends RefCounted
## Sect definitions: look, stance style, base stat bias, normal moveset and
## six skills each. Frame data is at 60 ticks/s; reach is metres beyond the
## attacker's body edge; dmg multiplies ATK (normals) or QI (skills).

const IDS := ["thieu_lam", "vo_dang", "nga_mi", "cai_bang", "duong_mon"]

static var _data: Dictionary = {}

## Build a move. Unlisted fields get defaults derived from damage.
static func mv(name: String, w: String, s: String, st: int, act: int, rec: int, dmg: float, reach: float, height := "mid", ex := {}) -> Dictionary:
	var m := {
		"name": name, "w": w, "s": s, "st": st, "act": act, "rec": rec,
		"dmg": dmg, "reach": reach, "h": height,
		"hs": int(12 + dmg * 7), "bs": int(6 + dmg * 3), "push": 1.4 + dmg * 0.9,
		"lunge": 0.0, "kd": false, "launch": 0.0, "hits": 1, "next": "",
		"cost": 0, "cd": 0, "kind": "strike", "armor": false, "fx": "hit",
		"tip": "weapon", "skill": false, "unblockable": false,
	}
	for k in ex:
		m[k] = ex[k]
	return m

static func sk(name: String, w: String, s: String, st: int, act: int, rec: int, dmg: float, reach: float, height: String, cost: int, cd_s: float, ex := {}) -> Dictionary:
	var e := ex.duplicate()
	e["cost"] = cost
	e["cd"] = int(cd_s * 60)
	e["skill"] = true
	return mv(name, w, s, st, act, rec, dmg, reach, height, e)

static func get_sect(id: String) -> Dictionary:
	if _data.is_empty():
		_build()
	return _data.get(id, _data["vo_dang"])

static func all() -> Array:
	if _data.is_empty():
		_build()
	var out := []
	for id in IDS:
		out.append(_data[id])
	return out

## Common unarmed kicks shared by everyone.
static func _kicks(k2_name := "Toàn Phong Cước") -> Dictionary:
	return {
		"k1": mv("Đăng Sơn Cước", "fkick_w", "fkick", 9, 3, 13, 1.1, 0.95, "mid", {"next": "k2", "tip": "foot_r", "fx": "kick"}),
		"k2": mv(k2_name, "round_w", "round", 12, 4, 18, 1.5, 1.0, "high", {"push": 4.0, "tip": "foot_r", "fx": "kick"}),
		"fk": mv("Trắc Thích Cước", "skick_w", "skick", 13, 4, 18, 1.6, 1.15, "mid", {"push": 5.0, "lunge": 1.5, "tip": "foot_l", "fx": "kick"}),
		"dk": mv("Tảo Đường Thối", "sweep_w", "sweep", 12, 4, 22, 1.2, 1.1, "low", {"kd": true, "tip": "foot_r", "fx": "kick"}),
		"jk": mv("Phi Cước", "jump", "jkick", 6, 8, 8, 1.3, 0.95, "over", {"tip": "foot_l", "fx": "kick", "air": true}),
		"throw": mv("Cầm Nã Thủ", "grab", "heave", 5, 2, 30, 1.4, 0.55, "mid", {"kind": "throw", "unblockable": true, "tip": "hand_r", "fx": "kick", "launch": 6.5, "push": -3.0}),
	}

static func _build() -> void:
	# ------------------------------------------------------------ Thiếu Lâm
	var tl := {
		"id": "thieu_lam", "name": "Thiếu Lâm", "weapon_name": "Côn", "style": "staff",
		"desc": "Cương mãnh, da đồng xương sắt. Côn dài, đòn nặng, máu trâu nhưng chậm.",
		"elem": Color(1.0, 0.75, 0.25),
		"bias": {"luc": 1, "than": -1, "noi": 1, "the": 2},
		"speed": 0.9,
		"look": {"robe": Color(0.92, 0.55, 0.12), "trim": Color(0.62, 0.14, 0.1), "pants": Color(0.82, 0.5, 0.14), "head_style": "bald", "weapon": "staff", "beads": true, "sash": Color(0.62, 0.14, 0.1), "bulk": 1.08},
		"moves": {
			"p1": mv("Côn Điểm", "staff_poke_w", "staff_poke", 9, 3, 13, 1.0, 1.1, "mid", {"next": "p2", "fx": "blunt"}),
			"p2": mv("Hoành Tảo Côn", "slash_h_w", "slash_h", 10, 4, 15, 1.2, 1.15, "high", {"next": "p3", "fx": "blunt"}),
			"p3": mv("Lực Phách Hoa Sơn", "staff_over_w", "staff_over", 15, 4, 22, 2.0, 1.25, "over", {"kd": true, "fx": "blunt"}),
			"fp": mv("Trực Đảo Hoàng Long", "staff_poke_w", "staff_poke", 12, 4, 18, 1.5, 1.2, "mid", {"lunge": 4.0, "push": 4.0, "fx": "blunt"}),
			"dp": mv("Bàn Căn Côn", "staff_sweep_w", "staff_sweep", 10, 4, 16, 0.9, 1.25, "low", {"fx": "blunt"}),
			"jp": mv("Thiên Côn Hạ", "jump", "staff_over", 7, 6, 10, 1.3, 1.3, "over", {"air": true, "fx": "blunt"}),
		},
		"skills": [
			sk("La Hán Quyền", "jab_w", "cross", 9, 18, 16, 0.8, 1.0, "mid", 25, 4.0, {"hits": 3, "lunge": 2.0, "tip": "hand_r", "fx": "palm"}),
			sk("Kim Cang Hộ Thể", "cast_w", "victory", 10, 2, 14, 0.0, 0.0, "mid", 35, 16.0, {"kind": "buff", "buff": {"def": 1.25, "armor": true, "t": 180}, "lvl": 3}),
			sk("Phong Ma Côn Pháp", "spin", "slash_h", 12, 30, 20, 0.75, 1.5, "mid", 35, 6.0, {"hits": 4, "armor": true, "lvl": 6, "fx": "blunt"}),
			sk("Sư Tử Hống", "cast_w", "cast", 16, 6, 24, 0.9, 2.2, "mid", 40, 10.0, {"hs": 70, "bs": 30, "push": 3.0, "unblockable": true, "lvl": 10, "fx": "roar"}),
			sk("Phục Hổ Thăng Thiên", "rising_w", "rising", 8, 6, 26, 1.8, 1.3, "high", 35, 7.0, {"launch": 9.0, "lvl": 15, "fx": "blunt"}),
			sk("Đạt Ma Kim Thân", "cast_w", "staff_over", 20, 40, 30, 1.3, 1.6, "mid", 100, 30.0, {"kind": "rush", "hits": 6, "lunge": 6.0, "armor": true, "ult": true, "launch": 7.0, "lvl": 20, "fx": "blunt"}),
		],
	}
	tl.moves.merge(_kicks("Kim Cang Thối"))
	# ------------------------------------------------------------- Võ Đang
	var vd := {
		"id": "vo_dang", "name": "Võ Đang", "weapon_name": "Kiếm", "style": "sword",
		"desc": "Lấy nhu chế cương. Kiếm pháp cân bằng, phản đòn và kiếm khí tầm xa.",
		"elem": Color(0.45, 0.75, 1.0),
		"bias": {"luc": 0, "than": 1, "noi": 2, "the": 0},
		"speed": 1.0,
		"look": {"robe": Color(0.38, 0.5, 0.66), "trim": Color(0.93, 0.93, 0.96), "pants": Color(0.2, 0.22, 0.3), "head_style": "bun", "weapon": "sword", "sash": Color(0.15, 0.15, 0.22)},
		"moves": {
			"p1": mv("Thanh Phong Phất Liễu", "slash_h_w", "slash_h", 7, 3, 12, 1.0, 1.15, "mid", {"next": "p2", "fx": "slash"}),
			"p2": mv("Bạch Hạc Lượng Sí", "slash_hi_w", "slash_hi", 8, 3, 14, 1.1, 1.15, "high", {"next": "p3", "fx": "slash"}),
			"p3": mv("Tiên Nhân Chỉ Lộ", "thrust_w", "thrust", 11, 4, 20, 1.7, 1.45, "mid", {"lunge": 3.0, "push": 4.5, "fx": "slash"}),
			"fp": mv("Thanh Xà Xuất Động", "thrust_w", "thrust", 12, 4, 18, 1.4, 1.55, "mid", {"lunge": 4.5, "fx": "slash"}),
			"dp": mv("Hạ Bàn Kiếm", "rising_w", "lowpunch", 9, 3, 15, 0.9, 1.25, "low", {"fx": "slash"}),
			"jp": mv("Phi Kiếm", "jump", "jpunch", 6, 6, 10, 1.2, 1.15, "over", {"air": true, "fx": "slash"}),
		},
		"skills": [
			sk("Thái Cực Kiếm", "slash_h_w", "spin", 10, 21, 18, 0.7, 1.35, "mid", 25, 4.0, {"hits": 3, "lunge": 1.5, "fx": "slash"}),
			sk("Lưỡng Nghi Hóa Kình", "block", "block", 3, 40, 12, 2.2, 1.4, "mid", 30, 8.0, {"kind": "counter", "lvl": 3, "fx": "slash"}),
			sk("Kiếm Khí Trường Hồng", "slash_hi_w", "slash_h", 12, 3, 22, 1.6, 0.0, "mid", 30, 5.0, {"kind": "proj", "proj": {"speed": 11.0, "y": 1.1, "n": 1, "vis": "crescent"}, "lvl": 6, "fx": "slash"}),
			sk("Thê Vân Tung", "jump", "staff_over", 10, 10, 18, 1.9, 1.2, "over", 35, 7.0, {"kind": "leap", "kd": true, "lvl": 10, "fx": "slash"}),
			sk("Tọa Vong Tâm Pháp", "cast_w", "cast_w", 12, 2, 16, 0.0, 0.0, "mid", 20, 16.0, {"kind": "buff", "buff": {"atk": 1.35, "regen_en": 8.0, "t": 420}, "lvl": 15}),
			sk("Thái Cực Vô Cực", "rising_w", "slash_hi", 18, 30, 30, 1.0, 0.0, "mid", 100, 30.0, {"kind": "proj", "proj": {"speed": 9.0, "y": 1.0, "n": 6, "gap": 5, "vis": "sword"}, "ult": true, "kd": true, "unblockable": true, "lvl": 20, "fx": "slash"}),
		],
	}
	vd.moves.merge(_kicks("Bãi Liên Cước"))
	# --------------------------------------------------------------- Nga Mi
	var nm := {
		"id": "nga_mi", "name": "Nga Mi", "weapon_name": "Song Kiếm", "style": "dual",
		"desc": "Thân pháp nhanh như gió, song kiếm liên hoàn, biết tự trị thương.",
		"elem": Color(1.0, 0.6, 0.8),
		"bias": {"luc": -1, "than": 3, "noi": 2, "the": -1},
		"speed": 1.12,
		"look": {"model": "NgaMi", "robe": Color(0.96, 0.94, 0.96), "trim": Color(0.88, 0.42, 0.58), "pants": Color(0.86, 0.76, 0.84), "head_style": "long", "weapon": "dual", "female": true, "bulk": 0.86, "height": 0.95, "sash": Color(0.88, 0.38, 0.55), "robe_len": 0.58},
		"moves": {
			"p1": mv("Phất Vân Thủ", "jab_w", "jab", 5, 3, 10, 0.9, 1.1, "mid", {"next": "p2", "tip": "hand_l", "fx": "slash"}),
			"p2": mv("Song Yến Phi", "cross_w", "cross", 6, 3, 11, 1.0, 1.1, "high", {"next": "p3", "fx": "slash"}),
			"p3": mv("Hồi Phong Vũ Liễu", "slash_h_w", "spin", 9, 10, 16, 0.85, 1.1, "mid", {"hits": 2, "push": 3.0, "fx": "slash"}),
			"fp": mv("Yến Tử Xuyên Lâm", "thrust_w", "thrust", 9, 4, 15, 1.2, 1.2, "mid", {"lunge": 5.5, "fx": "slash"}),
			"dp": mv("Thủy Để Lao Nguyệt", "rising_w", "lowpunch", 7, 3, 13, 0.8, 1.05, "low", {"fx": "slash"}),
			"jp": mv("Lạc Hoa Kiếm", "jump", "jpunch", 5, 6, 9, 1.1, 1.0, "over", {"air": true, "fx": "slash"}),
		},
		"skills": [
			sk("Lưu Thủy Kiếm", "jab_w", "cross", 7, 25, 16, 0.5, 1.1, "mid", 25, 4.0, {"hits": 5, "lunge": 1.8, "fx": "slash"}),
			sk("Phật Quang Phổ Chiếu", "cast_w", "victory", 18, 2, 16, 0.0, 0.0, "mid", 40, 15.0, {"kind": "heal", "heal": 0.16, "lvl": 3}),
			sk("Phiêu Tuyết Xuyên Vân", "thrust_w", "thrust", 8, 10, 18, 0.7, 0.9, "mid", 30, 6.0, {"kind": "blink", "hits": 2, "lvl": 6, "fx": "slash"}),
			sk("Kim Đỉnh Miên Chưởng", "palm_w", "palm", 11, 4, 20, 1.4, 1.0, "mid", 30, 7.0, {"hs": 55, "push": 2.0, "tip": "hand_r", "lvl": 10, "fx": "palm"}),
			sk("Thiên Nữ Tán Hoa", "toss_w", "toss", 10, 3, 18, 0.6, 0.0, "mid", 30, 6.0, {"kind": "proj", "proj": {"speed": 12.0, "y": 1.2, "n": 3, "gap": 6, "vis": "petal"}, "lvl": 15, "fx": "slash"}),
			sk("Phổ Độ Liên Hoa", "cast_w", "cast", 20, 24, 30, 0.9, 2.4, "mid", 100, 30.0, {"kind": "strike", "hits": 4, "ult": true, "heal": 0.2, "launch": 7.0, "unblockable": true, "lvl": 20, "fx": "lotus"}),
		],
	}
	nm.moves.merge(_kicks("Liên Hoàn Cước"))
	# -------------------------------------------------------------- Cái Bang
	var cb := {
		"id": "cai_bang", "name": "Cái Bang", "weapon_name": "Chưởng", "style": "palm",
		"desc": "Chưởng lực hùng hậu, quyền cước mạnh, càng đánh càng hăng.",
		"elem": Color(1.0, 0.85, 0.3),
		"bias": {"luc": 2, "than": 0, "noi": 1, "the": 1},
		"speed": 1.05,
		"look": {"robe": Color(0.46, 0.4, 0.26), "trim": Color(0.32, 0.46, 0.26), "pants": Color(0.36, 0.3, 0.22), "head_style": "headband", "weapon": "none", "bulk": 1.15, "sash": Color(0.56, 0.36, 0.16), "bracers": true, "beard": true},
		"moves": {
			"p1": mv("Khai Môn Quyền", "jab_w", "jab", 6, 3, 11, 1.05, 1.05, "mid", {"next": "p2", "tip": "hand_l", "fx": "punch"}),
			"p2": mv("Băng Quyền", "cross_w", "cross", 7, 3, 13, 1.3, 1.05, "high", {"next": "p3", "tip": "hand_r", "fx": "punch"}),
			"p3": mv("Thôi Sơn Chưởng", "palm_w", "palm", 11, 4, 20, 2.1, 1.05, "mid", {"push": 5.5, "tip": "hand_r", "fx": "palm"}),
			"fp": mv("Mãnh Hổ Hạ Sơn", "palm_w", "palm", 11, 4, 18, 1.6, 1.05, "mid", {"lunge": 5.0, "push": 4.5, "tip": "hand_r", "fx": "palm"}),
			"dp": mv("Hạ Bàn Quyền", "jab_w", "lowpunch", 7, 3, 13, 0.9, 1.0, "low", {"tip": "hand_r", "fx": "punch"}),
			"jp": mv("Phi Hổ Quyền", "jump", "jpunch", 6, 6, 10, 1.25, 0.85, "over", {"air": true, "tip": "hand_r", "fx": "punch"}),
		},
		"skills": [
			sk("Hàng Ma Chưởng", "dpalm_w", "dpalm", 12, 5, 22, 2.4, 1.3, "mid", 25, 4.5, {"kd": true, "launch": 5.0, "push": 6.5, "armor": true, "tip": "hand_r", "fx": "palm"}),
			sk("Túy Quyền", "upper_w", "cross", 8, 28, 18, 0.65, 1.1, "mid", 30, 6.0, {"hits": 4, "lunge": 1.5, "tip": "hand_r", "lvl": 3, "fx": "punch"}),
			sk("Long Hống Chưởng", "dpalm_w", "dpalm", 14, 3, 22, 1.7, 0.0, "mid", 30, 5.0, {"kind": "proj", "proj": {"speed": 9.0, "y": 1.0, "n": 1, "vis": "dragon"}, "lvl": 6, "fx": "palm"}),
			sk("Đả Cẩu Phản Kích", "block", "block", 3, 40, 12, 2.4, 1.0, "mid", 30, 8.0, {"kind": "counter", "tip": "hand_r", "lvl": 10, "fx": "palm"}),
			sk("Tửu Thần Cuồng Khí", "cast_w", "victory", 12, 2, 14, 0.0, 0.0, "mid", 25, 16.0, {"kind": "buff", "buff": {"atk": 1.35, "spd": 1.12, "t": 420}, "lvl": 15}),
			sk("Phi Long Tại Thiên", "upper_w", "upper", 16, 36, 30, 1.25, 1.2, "mid", 100, 30.0, {"kind": "rush", "hits": 6, "lunge": 6.5, "armor": true, "ult": true, "launch": 9.0, "tip": "hand_r", "lvl": 20, "fx": "palm"}),
		],
	}
	cb.moves.merge(_kicks("Thần Long Bãi Vĩ"))
	# ------------------------------------------------------------- Đường Môn
	var dm := {
		"id": "duong_mon", "name": "Đường Môn", "weapon_name": "Ám Khí", "style": "dagger",
		"desc": "Ám khí tầm xa, độc dược. Giữ khoảng cách, tiêu hao đối thủ.",
		"elem": Color(0.55, 1.0, 0.45),
		"bias": {"luc": 0, "than": 2, "noi": 2, "the": 0},
		"speed": 1.1,
		"look": {"robe": Color(0.24, 0.17, 0.3), "trim": Color(0.58, 0.16, 0.22), "pants": Color(0.13, 0.11, 0.16), "head_style": "hood", "outfit": "Ranger", "robe_len": 0.0, "weapon": "daggers", "sash": Color(0.58, 0.16, 0.22)},
		"moves": {
			"p1": mv("Chủy Thủ Thích", "jab_w", "cross", 5, 3, 11, 1.0, 1.1, "mid", {"next": "p2", "fx": "slash"}),
			"p2": mv("Hồi Đao Trảm", "slash_h_w", "slash_h", 7, 3, 13, 1.1, 1.1, "high", {"next": "p3", "fx": "slash"}),
			"p3": mv("Thượng Khiêu Đao", "rising_w", "rising", 10, 4, 20, 1.6, 1.05, "mid", {"launch": 6.5, "fx": "slash"}),
			"fp": mv("Phi Đao", "toss_w", "toss", 9, 2, 16, 0.85, 0.0, "high", {"kind": "proj", "proj": {"speed": 15.0, "y": 1.3, "n": 1, "vis": "knife"}, "fx": "slash"}),
			"dp": mv("Địa Xà Thích", "jab_w", "lowpunch", 6, 3, 12, 0.8, 0.95, "low", {"fx": "slash"}),
			"jp": mv("Không Trung Phi Đao", "jump", "toss", 6, 2, 12, 0.65, 0.0, "mid", {"air": true, "kind": "proj", "proj": {"speed": 14.0, "y": 0.0, "vy": -6.0, "n": 1, "vis": "knife"}, "fx": "slash"}),
		},
		"skills": [
			sk("Phi Đao Tam Liên", "toss_w", "toss", 9, 3, 18, 0.7, 0.0, "mid", 25, 4.0, {"kind": "proj", "proj": {"speed": 15.0, "y": 1.2, "n": 3, "gap": 5, "vis": "knife"}}),
			sk("Đoạt Mệnh Độc Châm", "toss_w", "toss", 9, 2, 16, 0.5, 0.0, "high", 25, 8.0, {"kind": "proj", "proj": {"speed": 18.0, "y": 1.35, "n": 1, "vis": "needle"}, "poison": 0.07, "lvl": 3}),
			sk("Ảnh Tung Bộ", "dodge", "cross", 10, 4, 18, 1.4, 1.0, "mid", 30, 6.0, {"kind": "blink", "lvl": 6, "fx": "slash"}),
			sk("Lôi Hỏa Đạn", "toss_w", "toss", 12, 2, 20, 1.8, 0.0, "mid", 35, 8.0, {"kind": "proj", "proj": {"speed": 6.5, "y": 1.4, "vy": 6.0, "grav": 16.0, "n": 1, "vis": "bomb"}, "kd": true, "launch": 6.0, "unblockable": true, "lvl": 10, "fx": "fire"}),
			sk("Bạo Vũ Lê Hoa", "cast_w", "toss", 12, 3, 22, 0.35, 0.0, "mid", 35, 7.0, {"kind": "proj", "proj": {"speed": 16.0, "y": 1.1, "n": 7, "gap": 2, "spread": 0.35, "vis": "needle"}, "lvl": 15}),
			sk("Vạn Độc Thiên La", "cast_w", "toss", 18, 40, 30, 0.75, 0.0, "mid", 100, 30.0, {"kind": "rain", "proj": {"n": 10, "gap": 4, "vis": "knife"}, "poison": 0.12, "unblockable": true, "ult": true, "lvl": 20, "fx": "slash"}),
		],
	}
	dm.moves.merge(_kicks("Quỷ Ảnh Cước"))
	for s in [tl, vd, nm, cb, dm]:
		# skill unlock levels default: first skill at 1
		for i in s.skills.size():
			var m: Dictionary = s.skills[i]
			m["slot"] = i
			if not m.has("lvl"):
				m["lvl"] = 1
		_data[s.id] = s
