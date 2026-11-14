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

## Mixamo attack clips (assets_src/animation), timed from tools/hand_check.gd:
## move key -> [clip, from, hit (hand/weapon fully out), to, optional hit_to]
## With hit_to the clip sweeps hit -> hit_to through the active frames, also for
## multi-hit moves (no per-hit replay, which spun spinning clips round and round).
const MIX := {
	"jab": ["m/Jab", 0.08, 0.25, 0.55], "jab_w": ["m/Jab", 0.08, 0.25, 0.55],
	"cross": ["m/Cross", 0.3, 0.55, 0.8], "cross_w": ["m/Cross", 0.3, 0.55, 0.8],
	"lowpunch": ["m/Jab", 0.08, 0.25, 0.55],
	"upper": ["m/Uppercut", 0.18, 0.38, 0.72],
	"palm": ["m/Palm", 0.2, 0.45, 0.75],
	"dpalm": ["m/Double_Palm", 0.25, 0.48, 0.8],
	"slash_h": ["m/Slash_H", 0.2, 0.42, 0.75], "staff_sweep": ["m/Slash_H", 0.2, 0.42, 0.75],
	"slash_hi": ["m/Slash_Hi", 0.05, 0.24, 0.5],
	"rising": ["m/Rising", 0.3, 0.52, 0.8],
	# one turn (~370°, tools/spin_check.gd), swept through the active frames instead of replayed per hit
	"spin": ["m/Spin_Attack", 0.05, 0.28, 0.8, 0.62],
	"thrust": ["m/Thrust", 0.2, 0.45, 0.7], "staff_poke": ["m/Thrust", 0.2, 0.45, 0.7],
	"staff_over": ["m/Overhead", 0.1, 0.38, 0.7],
	"toss": ["m/Throw", 0.3, 0.43, 0.7],
	# side kick: right foot chambers 0.2, fully out 0.35-0.42, body turns ~155° (no spin)
	"skick": ["m/Side_Kick", 0.12, 0.35, 0.7, 0.42],
	# 2H area cast: hands raise 0.1-0.15, crouch and push out fully at 0.45
	"cast": ["m/Cast", 0.12, 0.4, 0.52, 0.46],
	# power up (buffs/heals): arms rise 0.15, flexed hold 0.25-0.7 (buffs last ~26 frames, so only the rise + first flex)
	"victory": ["m/Power_Up", 0.08, 0.25, 0.45, 0.35], "cast_w": ["m/Power_Up", 0.08, 0.25, 0.45, 0.35],
	# ---- per-sect clips (DANH_SACH_MIXAMO.md section G), timed with tools/peak_check.gd
	# Thiếu Lâm
	"tl_quad": ["m/ThieuLam_Quad_Punch", 0.17, 0.237, 0.68, 0.537],    # 4 punches 0.24/0.33/0.44/0.54
	"tl_roar": ["m/ThieuLam_Roar", 0.2, 0.42, 0.65, 0.55],             # stomp 0.2, lean-in roar 0.4-0.6
	"tl_smash": ["m/ThieuLam_Smash", 0.05, 0.3, 0.8, 0.65],            # raise 0.33, slam 0.4, second slam 0.65
	# Võ Đang
	"vd_combo": ["m/VoDang_Sword_Combo", 0.1, 0.237, 0.62, 0.55],      # slashes 0.24 and 0.54
	"vd_jump": ["m/VoDang_Jump_Attack", 0.2, 0.47, 0.7, 0.55],         # sword overhead 0.35, cut down 0.47-0.55
	# Nga Mi (dual blades)
	"nm_a": ["m/NgaMi_Sword_Fast", 0.12, 0.2, 0.27],
	"nm_b": ["m/NgaMi_Sword_Fast", 0.24, 0.3, 0.4],
	"nm_flurry": ["m/NgaMi_Sword_Fast", 0.15, 0.2, 0.85, 0.72],        # cuts 0.2/0.3/0.5/0.71
	"pray": ["m/NgaMi_Pray", 0.0, 0.1, 0.5, 0.4],
	# Cái Bang
	"cb_combo": ["m/CaiBang_Punch_Combo", 0.2, 0.287, 0.75, 0.62],     # punches 0.29/0.4/0.51/0.61
	# Vovinam
	"martelo": ["m/Vovinam_Kick_1", 0.28, 0.45, 0.72, 0.5],            # roundhouse, foot up 0.45-0.5
	"chapa": ["m/Vovinam_Kick_2", 0.15, 0.375, 0.65, 0.48],            # leaning push kick 0.38-0.49
	"vn_elbow": ["m/Vovinam_Elbow", 0.3, 0.375, 0.68, 0.6],            # punch/elbow strikes 0.38-0.59
	"vn_knee": ["m/Vovinam_Knee", 0.2, 0.35, 0.6, 0.42],               # flying knee 0.33-0.4, hands strike down after
	# Đường Môn
	"dm_toss": ["m/DuongMon_Toss", 0.45, 0.6, 0.75],                   # quick flick, release 0.6
	"dm_grenade": ["m/DuongMon_Grenade", 0.33, 0.47, 0.6],             # overhand lob, release 0.45-0.5
	"dm_throw2": ["m/DuongMon_Throw2", 0.45, 0.64, 0.76],              # low throw, release 0.64
}

## Per-sect keys fall back to the shared clip when their FBX is missing.
const FALLBACK := {
	"tl_quad": "cross", "tl_roar": "cast", "tl_smash": "staff_over",
	"vd_combo": "spin", "vd_jump": "staff_over",
	"nm_a": "jab", "nm_b": "cross", "nm_flurry": "cross", "pray": "victory",
	"cb_combo": "upper", "drunk_fist": "cross",
	"martelo": "round", "chapa": "skick", "vn_elbow": "cross", "vn_knee": "upper", "vn_kicks": "round",
	"dm_toss": "toss", "dm_grenade": "toss", "dm_throw2": "toss",
}

## Multi-clip moves:
##  "seq": each hit-group of the active frames plays the next clip [clip, from, hit_to]
##  "arms": the arms play a second clip (layer) over the main clip's legs
const SPECIAL := {
	# Vovinam ult: roundhouse -> push kick -> side kick, each swung chamber -> extension
	"vn_kicks": {"clip": "m/Vovinam_Kick_1", "from": 0.28, "hit": 0.45, "to": 0.72, "seq": [
		["m/Vovinam_Kick_1", 0.3, 0.5], ["m/Vovinam_Kick_2", 0.2, 0.48], ["m/Side_Kick", 0.2, 0.42]]},
	# Cái Bang Túy Quyền: staggering drunk walk with a punch combo on the arms
	"drunk_fist": {"clip": "m/CaiBang_Drunk_Walk", "from": 0.0, "hit": 0.15, "hit_to": 0.6, "to": 0.75,
		"arms": ["m/CaiBang_Punch_Combo", 0.2, 0.287, 0.75, 0.62]},
}

static func attack(key: String, style: String) -> Dictionary:
	var weapon := style in WEAPON_STYLES
	if SPECIAL.has(key) and Avatar.has_clip(SPECIAL[key].clip):
		var ok := true
		for c in SPECIAL[key].get("seq", []):
			ok = ok and Avatar.has_clip(c[0])
		if SPECIAL[key].has("arms"):
			ok = ok and Avatar.has_clip(SPECIAL[key].arms[0])
		if ok:
			return SPECIAL[key]
	if MIX.has(key) and Avatar.has_clip(MIX[key][0]) and not (key == "lowpunch"):
		var mx: Array = MIX[key]
		var d := {"clip": mx[0], "from": mx[1], "hit": mx[2], "to": mx[3]}
		if mx.size() > 4:
			d["hit_to"] = mx[4]
		return d
	if FALLBACK.has(key):
		return attack(FALLBACK[key], style)
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
			# Side / push kick. Never Hurricane_Kick: it spins 4 full turns (1440°) and
			# squeezed into ~35 frames looked like a top (tools/spin_check.gd).
			if Avatar.has_clip("m/Side_Kick"):
				return {"clip": "m/Side_Kick", "from": 0.12, "hit": 0.42, "to": 0.78}
			if Avatar.has_clip("m/Front_Kick"):
				# push kick held a bit longer than the k1 front kick
				return {"clip": "m/Front_Kick", "from": 0.15, "hit": 0.45, "hit_to": 0.5, "to": 0.78}
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
