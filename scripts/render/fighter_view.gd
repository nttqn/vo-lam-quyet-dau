class_name FighterView
extends Node3D
## Visual puppet for a Fighter: positions the skinned Avatar and drives its
## clips from the logic state each frame, plus the weapon trail and aura.

var f: Fighter
var body: Avatar
var trail: MeshInstance3D
var _trail_pts: Array = []
var _trail_mat: StandardMaterial3D
var _walk_t := 0.0
var _t := 0.0
var _aura: OmniLight3D
var _yaw := 0.0
var _last_state := -1
var _last_move: Dictionary = {}

const YAW_TOWARD_CAM := 0.4
const BOW_FRAMES := 66
var intro_frame := -1   # set by the fight scene during the round intro

func _init(p_f: Fighter, look: Dictionary) -> void:
	f = p_f
	body = Avatar.new(look)

func _ready() -> void:
	add_child(body)
	trail = MeshInstance3D.new()
	trail.top_level = true
	trail.mesh = ImmediateMesh.new()
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	trail.material_override = _trail_mat
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)
	_aura = OmniLight3D.new()
	_aura.light_energy = 0.0
	_aura.omni_range = 3.0
	_aura.position = Vector3(0, 1.2, 0.6)
	add_child(_aura)
	_yaw = _target_yaw()
	_sync(0.0)

func _process(delta: float) -> void:
	_sync(delta)

func _target_yaw() -> float:
	if f.state in [Fighter.LYING, Fighter.KO, Fighter.AIRHIT]:
		return PI * 0.5 if f.facing > 0 else -PI * 0.5
	return PI * 0.5 - YAW_TOWARD_CAM if f.facing > 0 else -PI * 0.5 + YAW_TOWARD_CAM

func tip_node() -> Node3D:
	var t: String = f.move.get("tip", "weapon") if not f.move.is_empty() else "weapon"
	match t:
		"hand_r": return body.hand_r_tip
		"hand_l": return body.hand_l_tip
		"foot_r": return body.foot_r_tip
		"foot_l": return body.foot_l_tip
	return body.weapon_tip

func _sync(delta: float) -> void:
	_t += delta
	position = Vector3(f.x, f.y, 0)
	_yaw = lerp_angle(_yaw, _target_yaw(), minf(1.0, delta * 14.0)) if delta > 0 else _target_yaw()
	body.rotation.y = _yaw
	body.position = Vector3.ZERO
	body.overrides.clear()
	var style := f.style
	var changed := f.state != _last_state or (f.state == Fighter.ATTACK and f.move != _last_move)
	_last_state = f.state
	_last_move = f.move
	var blend := 0.1
	body.layer = {}
	var st_t := f.sf / 60.0   # seconds in the current state
	match f.state:
		Fighter.IDLE, Fighter.LAND:
			if intro_frame >= 0 and intro_frame < BOW_FRAMES:
				# pre-round salute
				body.pose("m/Bow", body.clip_len("m/Bow") * (0.06 + 0.56 * intro_frame / float(BOW_FRAMES)), 0.2)
			elif f.hold_back:
				body.pose("m/Block", body.clip_len("m/Block") * 0.4, blend)
			else:
				var ic := AnimMap.idle_clip(style)
				var L := body.clip_len(ic[0])
				var a: float = ic[1]
				var b: float = ic[2]
				var ph := fposmod(_t * 0.6, 2.0)
				var fr := a + (b - a) * (ph if ph < 1.0 else 2.0 - ph)
				if a == 0.0 and b == 1.0:
					body.pose(ic[0], _t + f.idx * 1.3, blend)   # full looping stance clip
				else:
					body.pose(ic[0], L * fr, blend)
		Fighter.WALK:
			var back := f.hold_back
			_walk_t += delta * absf(f.vx) / 1.6
			body.pose("m/Walk_Back" if back else "m/Walk_Fwd", _walk_t, blend)
		Fighter.DASH:
			_walk_t += delta * 1.4
			body.pose("a/Jog_Fwd", _walk_t, 0.06)
		Fighter.CROUCH:
			body.pose("m/Crouch_Idle", _t, blend)
			if f.hold_back:
				_low_guard(0.4)
		Fighter.JUMP:
			# rising half -> tuck at the apex -> falling half
			var k := clampf((Fighter.JUMP_V - f.vy) / (2.0 * Fighter.JUMP_V), 0.0, 1.0)
			body.pose("m/Jump", body.clip_len("m/Jump") * (0.3 + 0.32 * k), 0.08)
		Fighter.ATTACK:
			_attack(style)
		Fighter.BLOCKSTUN:
			var kb := clampf(float(f.sf) / maxf(1.0, f.stun), 0.0, 1.0)
			if f.hold_down:
				body.pose("m/Crouch_Idle", 0.3, 0.05)
				_low_guard(0.42 + 0.1 * sin(kb * PI))
			else:
				body.pose("m/Block", body.clip_len("m/Block") * (0.4 + 0.12 * sin(kb * PI)), 0.05)
		Fighter.HITSTUN:
			var heavy := f.stun > 20 and not f.hit_low
			var clip := "m/Hit_Head" if heavy else "m/Hit_Body"
			var kh := clampf(float(f.sf) / maxf(1.0, f.stun), 0.0, 1.0)
			body.pose(clip, body.clip_len(clip) * (0.04 + 0.42 * kh), 0.05)
		Fighter.AIRHIT:
			# dying fighters use the dramatic KO fall
			var fall := "m/KO" if f.dead else "m/Knockdown"
			var a0 := 0.08 if f.dead else 0.14
			body.pose(fall, body.clip_len(fall) * minf(a0 + 0.26, a0 + st_t * 0.55), 0.06)
		Fighter.LYING:
			if f.sf < 18:
				body.pose("m/Knockdown", body.clip_len("m/Knockdown") * (0.4 + 0.05 * f.sf / 18.0), 0.1)
			else:
				# start sitting up so the short GETUP state reads as one motion
				body.pose("m/Getup", body.clip_len("m/Getup") * (0.36 + 0.14 * (f.sf - 18) / 18.0), 0.2)
		Fighter.GETUP:
			body.pose("m/Getup", body.clip_len("m/Getup") * (0.5 + 0.22 * clampf(f.sf / 18.0, 0.0, 1.0)), 0.05)
		Fighter.KO:
			body.pose("m/KO", body.clip_len("m/KO") * minf(1.0, 0.34 + st_t * 0.35), 0.15)
		Fighter.DODGE:
			body.pose("m/Dodge", body.clip_len("m/Dodge") * (0.1 + 0.5 * clampf(f.sf / 20.0, 0.0, 1.0)), 0.05)
		Fighter.WIN:
			body.pose("m/Victory", minf(st_t, body.clip_len("m/Victory") * 0.5), 0.25)
		_:
			body.pose(AnimMap.idle_clip(style)[0], _t, blend)
	match f.state:
		Fighter.HITSTUN, Fighter.AIRHIT, Fighter.LYING, Fighter.THROWN: body.expr = "hurt"
		Fighter.KO: body.expr = "ko"
		Fighter.ATTACK, Fighter.BLOCKSTUN: body.expr = "attack"
		Fighter.WIN: body.expr = "win"
		_: body.expr = ""
	body.finish(delta)
	_update_trail()
	var aura_on: bool = (f.state == Fighter.ATTACK and f.move.get("skill", false)) or not f.buffs.is_empty()
	var col: Color = f.sect.get("elem", Color.WHITE)
	_aura.light_color = col
	_aura.light_energy = lerpf(_aura.light_energy, 2.2 if aura_on else 0.0, minf(1.0, delta * 8.0))

## Crouching legs with the standing block's arms (Mixamo has no low block).
func _low_guard(frac: float) -> void:
	body.layer = {"clip": "m/Block", "t": body.clip_len("m/Block") * frac, "bones": Avatar.ARM_BONES}

func _attack(style: String) -> void:
	var m := f.move
	var spec := AnimMap.attack(m.get("s", ""), style)
	var clip: String = spec.clip
	var L := body.clip_len(clip)
	var st := float(m.st)
	var act := float(m.act)
	var rec := float(m.rec)
	var sfv := float(f.sf)
	var fr: float
	var w := 0.0      # override weight
	if sfv < st:
		var k := sfv / maxf(1.0, st)
		fr = lerpf(spec.from, spec.hit, k)
		w = ease(k, 0.6)
	elif sfv < st + act:
		# optional "hit_to": keep the strike moving through the active frames (sweeps)
		fr = lerpf(spec.hit, spec.get("hit_to", spec.hit), (sfv - st) / maxf(1.0, act))
		var hits: int = m.get("hits", 1)
		if hits > 1:
			# replay the strike portion for every hit
			var per := act / hits
			var ph := fmod(sfv - st, per) / per
			fr = lerpf(spec.from + (spec.hit - spec.from) * 0.4, spec.to, ph)
		w = 1.0
	else:
		var r := (sfv - st - act) / maxf(1.0, rec)
		fr = lerpf(spec.get("hit_to", spec.hit), spec.to, r)
		w = 1.0 - ease(r, 0.5)
	body.pose(clip, L * fr, 0.07)
	if spec.has("ov"):
		for bn in spec.ov:
			var e: Vector3 = spec.ov[bn] * (PI / 180.0) * w
			body.overrides[bn] = Quaternion.from_euler(e)
	if spec.has("drop"):
		body.position.y = float(spec.drop) * w

func _update_trail() -> void:
	var im := trail.mesh as ImmediateMesh
	im.clear_surfaces()
	var active := f.state == Fighter.ATTACK and f.sf >= int(f.move.get("st", 0)) - 3 and f.sf <= int(f.move.get("st", 0)) + int(f.move.get("act", 0)) + 3
	var tip := tip_node()
	if active and tip != null and tip.is_inside_tree():
		var base: Vector3 = (tip.get_parent() as Node3D).global_position
		_trail_pts.push_front([tip.global_position, base.lerp(tip.global_position, 0.5)])
	elif not _trail_pts.is_empty():
		_trail_pts.pop_back()
	while _trail_pts.size() > 9:
		_trail_pts.pop_back()
	if _trail_pts.size() < 2:
		return
	var col: Color = f.sect.get("elem", Color.WHITE)
	if not f.move.get("skill", false):
		col = Color(1, 1, 1)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in _trail_pts.size():
		var a := 1.0 - float(i) / _trail_pts.size()
		im.surface_set_color(Color(col.r, col.g, col.b, a * 0.75))
		im.surface_add_vertex(_trail_pts[i][0])
		im.surface_set_color(Color(col.r, col.g, col.b, 0.0))
		im.surface_add_vertex(_trail_pts[i][1])
	im.surface_end()
