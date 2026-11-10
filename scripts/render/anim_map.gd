class_name AnimMap
extends RefCounted
## Maps move pose keys and fighter states to skeletal clips.
## Clip times are fractions of the clip length: from -> hit -> to.
## "ov" = extra bone rotations (degrees, local) faded in toward the hit.
## Bone axes on this rig: thigh X- swings the leg forward, calf X+ bends the
## knee, spine X+ leans forward, pelvis Y twists.

const WEAPON_STYLES := ["sword", "staff", "dual", "dagger", "saber", "spear"]

const SECT_IDLE := {"staff": "m/ThieuLam_Idle", "sword": "m/VoDang_Idle", "dual": "m/NgaMi_Idle", "palm": "m/CaiBang_Idle", "dagger": "m/DuongMon_Idle"}

static func idle_clip(style: String) -> Array:
	# [clip, fraction-from, fraction-to] looped by the view
	if SECT_IDLE.has(style) and Avatar.has_clip(SECT_IDLE[style]):
		return [SECT_IDLE[style], 0.0, 1.0]
	if style in WEAPON_STYLES:
		return ["a/Sword_Idle", 0.0, 1.0]
	return ["a/Punch_Enter", 0.82, 1.0]

static func attack(key: String, style: String) -> Dictionary:
	var weapon := style in WEAPON_STYLES
	match key:
		"jab", "jab_w":
			return {"clip": "a/Punch_Jab", "from": 0.05, "hit": 0.38, "to": 0.95}
		"cross", "cross_w":
			return {"clip": "a/Punch_Cross", "from": 0.05, "hit": 0.4, "to": 0.95}
		"upper":
			return {"clip": "b/Melee_Hook", "from": 0.0, "hit": 0.42, "to": 0.95}
		"palm", "dpalm", "cast":
			return {"clip": "a/Spell_Simple_Shoot", "from": 0.0, "hit": 0.42, "to": 1.0}
		"slash_h", "staff_sweep":
			return {"clip": "b/Sword_Regular_A", "from": 0.05, "hit": 0.4, "to": 0.85}
		"slash_hi":
			return {"clip": "b/Sword_Regular_B", "from": 0.05, "hit": 0.4, "to": 0.85}
		"rising":
			return {"clip": "b/Sword_Regular_C", "from": 0.05, "hit": 0.38, "to": 0.85}
		"spin":
			return {"clip": "b/Sword_Regular_Combo", "from": 0.05, "hit": 0.3, "to": 0.95}
		"thrust", "staff_poke":
			return {"clip": "b/Sword_Dash_RM", "from": 0.1, "hit": 0.45, "to": 0.9}
		"staff_over":
			return {"clip": "a/Sword_Attack", "from": 0.1, "hit": 0.45, "to": 0.9}
		"toss":
			return {"clip": "b/OverhandThrow", "from": 0.1, "hit": 0.45, "to": 0.95}
		"heave", "grab":
			return {"clip": "b/Melee_Hook", "from": 0.0, "hit": 0.45, "to": 0.95}
		"victory", "cast_w":
			return {"clip": "a/Spell_Simple_Enter", "from": 0.0, "hit": 0.8, "to": 1.0}
		"block":
			return {"clip": "b/Sword_Block", "from": 0.2, "hit": 0.5, "to": 0.6}
		"fkick":
			if Avatar.has_clip("m/Front_Kick"):
				# Capoeira Bencao: right foot chambers 0.2, full push 0.40-0.48
				return {"clip": "m/Front_Kick", "from": 0.12, "hit": 0.42, "to": 0.78}
			return {"clip": idle_clip(style)[0], "from": 0.9, "hit": 0.9, "to": 0.9,
				"ov": {"thigh_r": Vector3(-105, 0, 0), "calf_r": Vector3(8, 0, 0), "spine_01": Vector3(-12, 0, 0), "thigh_l": Vector3(-8, 0, 0)}}
		"skick":
			if Avatar.has_clip("m/Hurricane_Kick"):
				return {"clip": "m/Hurricane_Kick", "from": 0.12, "hit": 0.4, "to": 0.8}
			return {"clip": "m/Mma_Kick", "from": 0.1, "hit": 0.35, "to": 0.72}
		"round":
			# Mixamo MMA kick (assets_src/animation): chamber 0.2, full extension ~0.36
			return {"clip": "m/Mma_Kick", "from": 0.1, "hit": 0.35, "to": 0.72}
		"sweep":
			if Avatar.has_clip("m/Leg_Sweep"):
				# wide low stance with the leg sweeping out 0.30-0.37; later the clip spins away and rises into a high hook
				return {"clip": "m/Leg_Sweep", "from": 0.18, "hit": 0.31, "hit_to": 0.36, "to": 0.37}
			return {"clip": "a/Crouch_Idle", "from": 0.3, "hit": 0.3, "to": 0.3,
				"ov": {"pelvis": Vector3(0, 70, 0), "thigh_r": Vector3(-75, 0, -30), "calf_r": Vector3(-5, 0, 0), "spine_01": Vector3(25, 0, 0)}, "drop": -0.12}
		"lowpunch":
			return {"clip": "a/Punch_Jab", "from": 0.05, "hit": 0.38, "to": 0.95,
				"ov": {"thigh_l": Vector3(-80, 0, 0), "calf_l": Vector3(110, 0, 0), "thigh_r": Vector3(-20, 0, 0), "calf_r": Vector3(100, 0, 0), "spine_01": Vector3(20, 0, 0)}, "drop": -0.38}
		"jkick":
			if Avatar.has_clip("m/Flying_Kick"):
				# left foot peaks 0.22-0.32 (bake drops the clip's own hop; the sim does the jump)
				return {"clip": "m/Flying_Kick", "from": 0.1, "hit": 0.26, "to": 0.42}
			return {"clip": "b/NinjaJump_Idle", "from": 0.2, "hit": 0.3, "to": 0.4,
				"ov": {"thigh_r": Vector3(-100, 0, 0), "calf_r": Vector3(5, 0, 0), "spine_01": Vector3(-15, 0, 0)}}
		"jpunch":
			if weapon:
				return {"clip": "b/Sword_Regular_A", "from": 0.05, "hit": 0.4, "to": 0.85}
			return {"clip": "a/Punch_Cross", "from": 0.05, "hit": 0.4, "to": 0.95}
	if weapon:
		return {"clip": "b/Sword_Regular_A", "from": 0.05, "hit": 0.4, "to": 0.85}
	return {"clip": "a/Punch_Jab", "from": 0.05, "hit": 0.38, "to": 0.95}
