class_name Avatar
extends Node3D
## Skinned character built from Quaternius CC0 parts (outfit + head cut from
## the base body + hair), tinted per sect, with wuxia extras and a weapon.
## Animation: clips from two libraries sampled manually so the fight sim can
## drive exact timing; switching clips cross-fades from a pose snapshot.

const OUTFIT_DIR := "res://assets/models/outfits/"
const HAIR_DIR := "res://assets/models/hair/"
const BASE_DIR := "res://assets/models/base/"
const HEAD_BONES := ["Head", "neck_01"]

static var _head_cache := {}
static var _lib1: AnimationLibrary
static var _lib2: AnimationLibrary

var look: Dictionary
var female := false
var root: Node3D
var skel: Skeleton3D
var ap: AnimationPlayer
var weapon_tip: Node3D
var hand_r_tip: Node3D
var hand_l_tip: Node3D
var foot_r_tip: Node3D
var foot_l_tip: Node3D
var _tinted: Array[StandardMaterial3D] = []
var _flash := 0.0
var _clip := ""
var _snap: Array = []          # [pos, rot] per bone at the moment of a switch
var _blend_t := 0.0
var _blend_dur := 0.0
var overrides := {}            # bone name -> Quaternion applied after the clip

func _init(lk: Dictionary = {}) -> void:
	look = lk
	female = lk.get("female", false)

static func libs() -> Array:
	if _lib1 == null:
		_lib1 = load("res://assets/models/anims/ual1_ue.res")
		var u: Node = load("res://assets/models/anims/UAL2_Standard.glb").instantiate()
		_lib2 = (u.get_node("AnimationPlayer") as AnimationPlayer).get_animation_library("")
		# the sim owns horizontal motion: drop root-motion translation
		for an in _lib2.get_animation_list():
			var a: Animation = _lib2.get_animation(an)
			for t in range(a.get_track_count() - 1, -1, -1):
				if a.track_get_type(t) == Animation.TYPE_POSITION_3D and String(a.track_get_path(t)).ends_with(":root"):
					a.remove_track(t)
		u.free()
	return [_lib1, _lib2]

func _ready() -> void:
	_build()

# ------------------------------------------------------------- building
func _build() -> void:
	var g := "Female" if female else "Male"
	var outfit: String = look.get("outfit", "Peasant")
	root = load(OUTFIT_DIR + "%s_%s.gltf" % [g, outfit]).instantiate()
	add_child(root)
	skel = root.get_node("Armature/Skeleton3D")
	var robe: Color = look.get("robe", Color(0.3, 0.4, 0.6))
	var pants: Color = look.get("pants", robe.darkened(0.4))
	var boots: Color = look.get("boots", Color(0.3, 0.25, 0.2))
	var trim: Color = look.get("trim", robe.lightened(0.4))
	for m in skel.get_children():
		if not (m is MeshInstance3D):
			continue
		var mi := m as MeshInstance3D
		var n := String(mi.name)
		if n.contains("Head_Hood") and look.get("head_style", "") != "hood":
			mi.visible = false
			continue
		var col := robe
		if n.ends_with("Legs"):
			col = pants
		elif n.contains("Feet"):
			col = boots
		elif n.contains("Arms"):
			col = robe.lerp(trim, 0.25)
		elif n.contains("Belt") or n.contains("Bracer") or n.contains("Pauldron"):
			col = look.get("sash", trim)
		_tint(mi, col)
	# head (cut from the base body), eyes, eyebrows
	var hd := _head(g)
	var head := MeshInstance3D.new()
	head.mesh = hd.mesh
	head.skin = hd.skin
	skel.add_child(head)
	head.skeleton = NodePath("..")
	var skin_col: Color = look.get("skin", Color(1, 0.92, 0.85))
	var hm := (hd.mesh as Mesh).surface_get_material(0).duplicate() as StandardMaterial3D
	hm.albedo_color = Color(1.0, 0.9, 0.82).lerp(skin_col, 0.3)
	head.set_surface_override_material(0, hm)
	_tinted.append(hm)
	for part in hd.extras:
		var e := MeshInstance3D.new()
		e.mesh = part.mesh
		e.skin = part.skin
		skel.add_child(e)
		e.skeleton = NodePath("..")
		if String(part.name) == "Eyebrows":
			_hair_mat(e)
	# hair
	var hs: String = look.get("head_style", "bun")
	var hair := ""
	match hs:
		"bun", "crown": hair = "Hair_Buns"
		"long": hair = "Hair_Long"
		"headband", "wild": hair = "Hair_SimpleParted"
		"hat": hair = "Hair_Buns"
		"bald": hair = ""
		"hood": hair = "" if outfit == "Ranger" else "Hair_Buzzed"
	if hair != "":
		_attach_hair(hair)
	if look.get("beard", false):
		_attach_hair("Hair_Beard")
	_extras(hs)
	# weapon + strike markers
	var w: String = look.get("weapon", "none")
	var hr := _bone_att("hand_r")
	var hl := _bone_att("hand_l")
	var grip_r := _grip(hr)
	var grip_l := _grip(hl)
	match w:
		"dual":
			weapon_tip = Weapons.build("dual_blade", grip_r)
			Weapons.build("dual_blade", grip_l)
		"daggers":
			weapon_tip = Weapons.build("dagger", grip_r)
		"none":
			weapon_tip = Node3D.new()
			hr.add_child(weapon_tip)
		_:
			weapon_tip = Weapons.build(w, grip_r)
	hand_r_tip = _marker(hr, Vector3(0, 0.08, 0))
	hand_l_tip = _marker(hl, Vector3(0, 0.08, 0))
	foot_r_tip = _marker(_bone_att("ball_r"), Vector3.ZERO)
	foot_l_tip = _marker(_bone_att("ball_l"), Vector3.ZERO)
	# animation
	ap = AnimationPlayer.new()
	root.add_child(ap)
	var L := libs()
	ap.add_animation_library("a", L[0])
	ap.add_animation_library("b", L[1])
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for mi in skel.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _tint(mi: MeshInstance3D, col: Color) -> void:
	for s in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(s) as StandardMaterial3D
		if m == null:
			continue
		var nm := m.duplicate() as StandardMaterial3D
		var name := m.resource_name
		if name.contains("Peasant") or name.contains("Ranger"):
			var kind := "Peasant" if name.contains("Peasant") else "Ranger"
			nm.albedo_texture = load(OUTFIT_DIR + "T_%s_Gray.png" % kind)
			nm.albedo_color = col
		_tinted.append(nm)
		mi.set_surface_override_material(s, nm)

func _hair_mat(mi: MeshInstance3D) -> void:
	var hc: Color = look.get("hair", Color(0.08, 0.06, 0.05))
	for s in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(s) as StandardMaterial3D
		if m:
			var nm := m.duplicate() as StandardMaterial3D
			nm.albedo_color = hc.lightened(0.05) * 1.0
			mi.set_surface_override_material(s, nm)
			_tinted.append(nm)

func _attach_hair(name: String) -> void:
	var h: Node = load(HAIR_DIR + name + ".gltf").instantiate()
	for m in h.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.get_parent().remove_child(mi)
		skel.add_child(mi)
		mi.skeleton = NodePath("..")
		_hair_mat(mi)
	h.free()

func _bone_att(bone: String) -> BoneAttachment3D:
	var b := BoneAttachment3D.new()
	b.bone_name = bone
	skel.add_child(b)
	return b

func _grip(att: Node3D) -> Node3D:
	# hand bone: +Y runs along the fingers; the fist's thumb side is +Z.
	# The weapon builder wants its blade on -Y, so flip it to come out of the fist.
	var g := Node3D.new()
	g.position = Vector3(0.0, 0.08, 0.02)
	g.rotation_degrees = look.get("grip_rot", Vector3(-90, 0, 0))
	att.add_child(g)
	return g

func _marker(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

func _mat(col: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	_tinted.append(m)
	return m

## Wuxia touches built from primitives on bones: robe skirt, sash, hats.
func _extras(hs: String) -> void:
	var robe: Color = look.get("robe", Color(0.3, 0.4, 0.6))
	var sash: Color = look.get("sash", Color(0.7, 0.15, 0.1))
	var trim: Color = look.get("trim", robe.lightened(0.4))
	var bulk: float = look.get("bulk", 1.0)
	# sash knot + tails at the waist
	var pel := _bone_att("spine_01")
	var sm := _mat(sash)
	Weapons.seg(pel, Weapons.cyl(0.17 * bulk, 0.17 * bulk, 0.08, 14), sm, Vector3(0, 0.0, 0)).scale = Vector3(1.0, 1.0, 0.8)
	var tail := Weapons.seg(pel, Weapons.box(0.06, 0.32, 0.015), sm, Vector3(-0.06, -0.18, -0.14))
	tail.rotation_degrees = Vector3(10, 0, 8)
	# long robe skirt (front + back panels on the thighs so legs stay free)
	if look.get("robe_panels", false):
		var rl: float = look.get("robe_len", 0.5)
		for side in ["l", "r"]:
			var th := _bone_att("thigh_" + side)
			var rm := _mat(robe)
			var p := Weapons.seg(th, Weapons.box(0.19, rl, 0.012), rm, Vector3(0, rl * 0.45, 0.1))
			p.rotation_degrees = Vector3(-6, 0, 0)
			var p2 := Weapons.seg(th, Weapons.box(0.19, rl, 0.012), rm, Vector3(0, rl * 0.45, -0.1))
			p2.rotation_degrees = Vector3(6, 0, 0)
			Weapons.seg(th, Weapons.box(0.195, 0.03, 0.014), _mat(trim), Vector3(0, rl * 0.92, 0.104))
	var head := _bone_att("Head")
	match hs:
		"hat":
			var straw := _mat(Color(0.78, 0.66, 0.42))
			Weapons.seg(head, Weapons.cyl(0.02, 0.34, 0.13, 16), straw, Vector3(0, 0.22, 0.0))
		"crown":
			Weapons.seg(head, Weapons.box(0.09, 0.06, 0.05), _mat(Color(0.86, 0.66, 0.22), 0.35), Vector3(0, 0.23, -0.04))
		"headband":
			Weapons.seg(head, Weapons.cyl(0.115, 0.115, 0.035, 18), _mat(trim), Vector3(0, 0.12, -0.01))
		"bald":
			pass
	if look.get("beads", false):
		var ch := _bone_att("spine_03")
		var bm := _mat(Color(0.35, 0.15, 0.08), 0.4)
		for i in 14:
			var a := float(i) / 14.0 * TAU
			Weapons.seg(ch, Weapons.sph(0.022), bm, Vector3(sin(a) * 0.12, 0.12 + cos(a) * 0.14, 0.13 + absf(cos(a)) * 0.0))

# ------------------------------------------------------------- head cutting
static func _head(g: String) -> Dictionary:
	if _head_cache.has(g):
		return _head_cache[g]
	var base: Node = load(BASE_DIR + "Superhero_%s_FullBody.gltf" % g).instantiate()
	var body: MeshInstance3D = null
	var extras := []
	for m in base.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if String(mi.name).to_lower().begins_with("superhero"):
			body = mi
		else:
			extras.append({"name": mi.name, "mesh": mi.mesh, "skin": mi.skin})
	var skin: Skin = body.skin
	var keep_binds := {}
	for i in skin.get_bind_count():
		if String(skin.get_bind_name(i)) in HEAD_BONES:
			keep_binds[i] = true
	var src: ArrayMesh = body.mesh
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var nverts: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var per := bones.size() / maxi(1, nverts)
		var head_v := PackedByteArray()
		head_v.resize(nverts)
		for v in nverts:
			var w_head := 0.0
			for k in per:
				if keep_binds.has(bones[v * per + k]):
					w_head += weights[v * per + k]
			head_v[v] = 1 if w_head > 0.5 else 0
		var nidx := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			if head_v[idx[t]] + head_v[idx[t + 1]] + head_v[idx[t + 2]] >= 2:
				nidx.append(idx[t])
				nidx.append(idx[t + 1])
				nidx.append(idx[t + 2])
		arr[Mesh.ARRAY_INDEX] = nidx
		for ci in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
			arr[ci] = null
		var flags := src.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		out.surface_set_material(s, src.surface_get_material(s))
	var res := {"mesh": out, "skin": skin, "extras": extras}
	_head_cache[g] = res
	base.free()
	return res

# ------------------------------------------------------------- animation
func flash(amount := 1.0) -> void:
	_flash = maxf(_flash, amount)

## Show clip at time t (seconds). blend > 0 cross-fades when the clip changes.
func pose(clip: String, t: float, blend := 0.12) -> void:
	if clip != _clip:
		if _clip != "" and blend > 0.0:
			_snapshot()
			_blend_t = 0.0
			_blend_dur = blend
		else:
			_blend_dur = 0.0
		_clip = clip
		ap.play(clip)
	var a := ap.get_animation(clip)
	if a:
		if a.loop_mode != Animation.LOOP_NONE:
			t = fposmod(t, a.length)
		else:
			t = clampf(t, 0.0, a.length)
	ap.seek(t, true)

func clip_len(clip: String) -> float:
	var a := ap.get_animation(clip)
	return a.length if a else 1.0

func _snapshot() -> void:
	_snap.resize(skel.get_bone_count())
	for i in skel.get_bone_count():
		_snap[i] = [skel.get_bone_pose_position(i), skel.get_bone_pose_rotation(i)]

## Called after pose(): applies the cross-fade and procedural overrides.
func finish(delta: float) -> void:
	if _blend_dur > 0.0 and _blend_t < _blend_dur and not _snap.is_empty():
		_blend_t += delta
		var k := clampf(_blend_t / _blend_dur, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		for i in skel.get_bone_count():
			var s: Array = _snap[i]
			skel.set_bone_pose_position(i, (s[0] as Vector3).lerp(skel.get_bone_pose_position(i), k))
			skel.set_bone_pose_rotation(i, (s[1] as Quaternion).slerp(skel.get_bone_pose_rotation(i), k))
	for bn in overrides:
		var bi := skel.find_bone(bn)
		if bi >= 0:
			skel.set_bone_pose_rotation(bi, skel.get_bone_pose_rotation(bi) * (overrides[bn] as Quaternion))
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
	for m in _tinted:
		m.emission_enabled = _flash > 0.0
		if _flash > 0.0:
			m.emission = Color(1, 0.95, 0.85) * (_flash * 0.7)
