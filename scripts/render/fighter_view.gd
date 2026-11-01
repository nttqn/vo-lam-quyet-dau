class_name FighterView
extends Node3D
## Visual puppet for a Fighter: positions the Body and picks poses from the
## logic state each frame, plus shadow blob and weapon trail.

var f: Fighter
var body: Body
var trail: MeshInstance3D
var _trail_pts: Array = []
var _trail_mat: StandardMaterial3D
var _walk_phase := 0.0
var _t := 0.0
var _aura: OmniLight3D
var _yaw := 0.0

const YAW_TOWARD_CAM := 0.38

func _init(p_f: Fighter, look: Dictionary) -> void:
	f = p_f
	body = Body.new(look)

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
	_yaw = -YAW_TOWARD_CAM if f.facing > 0 else PI + YAW_TOWARD_CAM
	_sync(0.0, true)

func _process(delta: float) -> void:
	_sync(delta, false)

func tip_node() -> Node3D:
	var t: String = f.move.get("tip", "weapon") if not f.move.is_empty() else "weapon"
	match t:
		"hand_r": return body.hand_r_tip
		"hand_l": return body.hand_l_tip
		"foot_r": return body.foot_r_tip
		"foot_l": return body.foot_l_tip
	return body.weapon_tip

func _sync(delta: float, snap: bool) -> void:
	_t += delta
	position = Vector3(f.x, f.y, 0)
	# facing: turn smoothly, slight 3/4 toward the camera
	var target := -YAW_TOWARD_CAM if f.facing > 0 else PI + YAW_TOWARD_CAM
	if f.state == Fighter.LYING or f.state == Fighter.KO:
		target = -0.05 if f.facing > 0 else PI + 0.05
	_yaw = lerp_angle(_yaw, target, 1.0 if snap else minf(1.0, delta * 14.0))
	body.rotation.y = _yaw
	var style := f.style
	var p: Dictionary
	var k := minf(1.0, delta * 18.0)
	match f.state:
		Fighter.IDLE, Fighter.LAND:
			if f.hold_back:
				p = Poses.block(style, false)
			else:
				p = Poses.idle_breathe(style, _t)
		Fighter.WALK:
			_walk_phase += delta * 9.0 * absf(f.vx) / 2.5
			p = Poses.walk(style, _walk_phase, signf(f.vx) * f.facing)
			if f.hold_back:
				p = Poses.merge(p, _arms(Poses.block(style, false)))
		Fighter.CROUCH:
			p = Poses.block(style, true) if f.hold_back else Poses.crouch(style)
		Fighter.JUMP:
			p = Poses.jump(style)
			k = minf(1.0, delta * 12.0)
		Fighter.ATTACK:
			p = _attack_pose(style)
			k = minf(1.0, delta * 30.0)
		Fighter.BLOCKSTUN:
			p = Poses.block(style, f.hold_down)
			k = 1.0
		Fighter.HITSTUN:
			p = Poses.hurt_low(style) if f.hit_low else Poses.hurt(style, f.stun > 20)
			k = minf(1.0, delta * 25.0)
		Fighter.AIRHIT:
			p = Poses.airborne_hurt()
			k = minf(1.0, delta * 10.0)
		Fighter.LYING, Fighter.KO:
			p = Poses.lying()
			k = minf(1.0, delta * 12.0)
		Fighter.GETUP:
			p = Poses.getup(style)
			k = minf(1.0, delta * 10.0)
		Fighter.DODGE:
			p = Poses.dodge(style)
			k = minf(1.0, delta * 20.0)
		Fighter.DASH:
			_walk_phase += delta * 16.0
			p = Poses.add(Poses.walk(style, _walk_phase, 1.0), {"spine": Vector3(0, 0, -14)})
		Fighter.WIN:
			p = Poses.victory(style)
			k = minf(1.0, delta * 5.0)
		_:
			p = Poses.stance(style)
	if snap:
		body.apply_pose(p)
	else:
		body.blend_to(p, k)
	# air-hit tumble
	if f.state == Fighter.AIRHIT:
		body.rotation.z = lerpf(body.rotation.z, 0.0, 0.2)
	_update_trail(delta)
	# ki aura while a skill is active or buffed
	var aura_on: bool = (f.state == Fighter.ATTACK and f.move.get("skill", false)) or not f.buffs.is_empty()
	var col: Color = f.sect.get("elem", Color.WHITE)
	_aura.light_color = col
	_aura.light_energy = lerpf(_aura.light_energy, 2.2 if aura_on else 0.0, minf(1.0, delta * 8.0))

func _arms(p: Dictionary) -> Dictionary:
	var o := {}
	for n in ["sh_l", "el_l", "wr_l", "sh_r", "el_r", "wr_r", "chest"]:
		if p.has(n):
			o[n] = p[n]
	return o

func _named(name: String, style: String) -> Dictionary:
	match name:
		"jump": return Poses.jump(style)
		"block": return Poses.block(style, false)
		"victory": return Poses.victory(style)
		"dodge": return Poses.dodge(style)
		"stance": return Poses.stance(style)
	return Poses.key(name, style)

func _attack_pose(style: String) -> Dictionary:
	var m := f.move
	var w := _named(m.w, style)
	var s := _named(m.s, style)
	var sfv := float(f.sf)
	var stp := float(m.st)
	var act := float(m.act)
	var rec := float(m.rec)
	var hits: int = m.get("hits", 1)
	if sfv < stp:
		var t := sfv / maxf(1.0, stp)
		if t < 0.65:
			return Body.mix(Poses.stance(style), w, ease(t / 0.65, 0.5))
		return Body.mix(w, s, ease((t - 0.65) / 0.35, 2.0))
	if sfv < stp + act:
		if hits > 1:
			# alternate between windup and strike for each hit
			var per := act / hits
			var ph := fmod(sfv - stp, per) / per
			return Body.mix(s, w, 0.5 - 0.5 * cos(ph * TAU))
		return s
	var r := (sfv - stp - act) / maxf(1.0, rec)
	return Body.mix(s, Poses.stance(style), ease(r, 0.6))

func _update_trail(_delta: float) -> void:
	var im := trail.mesh as ImmediateMesh
	im.clear_surfaces()
	var active := f.state == Fighter.ATTACK and f.sf >= int(f.move.get("st", 0)) - 2 and f.sf <= int(f.move.get("st", 0)) + int(f.move.get("act", 0)) + 3
	var tip := tip_node()
	var base: Node3D = body.j["wr_r"] if f.move.get("tip", "weapon") == "weapon" else (tip.get_parent() as Node3D)
	if active and tip != null:
		_trail_pts.push_front([tip.global_position, base.global_position.lerp(tip.global_position, 0.45)])
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
		var c := Color(col.r, col.g, col.b, a * 0.75)
		im.surface_set_color(c)
		im.surface_add_vertex(_trail_pts[i][0])
		im.surface_set_color(Color(col.r, col.g, col.b, 0.0))
		im.surface_add_vertex(_trail_pts[i][1])
	im.surface_end()
