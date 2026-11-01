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
	match f.state:
		Fighter.IDLE, Fighter.LAND:
			if f.hold_back:
				body.pose("b/Sword_Block", body.clip_len("b/Sword_Block") * 0.5, blend)
			else:
				var ic := AnimMap.idle_clip(style)
				var L := body.clip_len(ic[0])
				var a: float = ic[1]
				var b: float = ic[2]
				var ph := fposmod(_t * 0.6, 2.0)
				var fr := a + (b - a) * (ph if ph < 1.0 else 2.0 - ph)
				body.pose(ic[0], L * fr, blend)
		Fighter.WALK:
			var back := f.hold_back
			_walk_t += delta * absf(f.vx) / 1.6 * (-1.0 if back else 1.0)
			if back:
				body.pose("b/Sword_Block", body.clip_len("b/Sword_Block") * 0.5, blend)
				body.overrides["thigh_l"] = Quaternion.from_euler(Vector3(deg_to_rad(sin(_t * 9.0) * 18.0), 0, 0))
				body.overrides["thigh_r"] = Quaternion.from_euler(Vector3(deg_to_rad(-sin(_t * 9.0) * 18.0), 0, 0))
			else:
				body.pose("a/Walk", _walk_t, blend)
		Fighter.DASH:
			_walk_t += delta * 1.4
			body.pose("a/Jog_Fwd", _walk_t, 0.06)
		Fighter.CROUCH:
			if f.hold_back:
				body.pose("a/Crouch_Idle", 0.3, blend)
				body.overrides["upperarm_r"] = Quaternion.from_euler(Vector3(0, 0, 0))
			else:
				body.pose("a/Crouch_Idle", _t, blend)
		Fighter.JUMP:
			if f.sf < 10 and f.vy > 0:
				body.pose("b/NinjaJump_Start", body.clip_len("b/NinjaJump_Start") * (0.4 + f.sf / 25.0), 0.05)
			else:
				body.pose("b/NinjaJump_Idle", _t, 0.12)
		Fighter.ATTACK:
			_attack(style)
		Fighter.BLOCKSTUN:
			if f.hold_down:
				body.pose("a/Crouch_Idle", 0.3, 0.05)
			else:
				body.pose("b/Sword_Block", body.clip_len("b/Sword_Block") * 0.55, 0.05)
		Fighter.HITSTUN:
			var clip := "a/Hit_Head" if (f.stun > 20 and not f.hit_low) else "a/Hit_Chest"
			var L2 := body.clip_len(clip)
			body.pose(clip, L2 * clampf(float(f.sf) / maxf(1.0, f.stun), 0.0, 1.0), 0.05)
		Fighter.AIRHIT:
			var L3 := body.clip_len("b/Hit_Knockback")
			body.pose("b/Hit_Knockback", minf(L3 * 0.55, f.sf / 60.0 * 1.4), 0.06)
		Fighter.LYING, Fighter.KO:
			var L4 := body.clip_len("b/Hit_Knockback")
			body.pose("b/Hit_Knockback", minf(L4, L4 * 0.55 + f.sf / 60.0 * 1.6), 0.08)
		Fighter.GETUP:
			var L5 := body.clip_len("b/LayToIdle")
			body.pose("b/LayToIdle", L5 * clampf(f.sf / 18.0, 0.0, 1.0), 0.05)
		Fighter.DODGE:
			var L6 := body.clip_len("a/Roll")
			body.pose("a/Roll", L6 * clampf(1.0 - f.sf / 20.0, 0.0, 1.0) * 0.8, 0.05)
		Fighter.WIN:
			body.pose("b/Idle_FoldArms", _t, 0.25)
		_:
			body.pose(AnimMap.idle_clip(style)[0], _t, blend)
	body.finish(delta)
	_update_trail()
	var aura_on: bool = (f.state == Fighter.ATTACK and f.move.get("skill", false)) or not f.buffs.is_empty()
	var col: Color = f.sect.get("elem", Color.WHITE)
	_aura.light_color = col
	_aura.light_energy = lerpf(_aura.light_energy, 2.2 if aura_on else 0.0, minf(1.0, delta * 8.0))

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
		fr = spec.hit
		var hits: int = m.get("hits", 1)
		if hits > 1:
			# replay the strike portion for every hit
			var per := act / hits
			var ph := fmod(sfv - st, per) / per
			fr = lerpf(spec.from + (spec.hit - spec.from) * 0.4, spec.to, ph)
		w = 1.0
	else:
		var r := (sfv - st - act) / maxf(1.0, rec)
		fr = lerpf(spec.hit, spec.to, r)
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
