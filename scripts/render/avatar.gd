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
static var _lib3: AnimationLibrary

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
## Second clip on a subset of bones: {"clip": "m/Block", "t": 0.5, "bones": [...]}
## e.g. crouching legs + blocking arms. Cleared by the caller each frame.
var layer := {}
const ARM_BONES := ["clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]
var _shaders: Array[ShaderMaterial] = []
var _face_scale := Vector3.ONE
var _head_bone := -1

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
		if ResourceLoader.exists("res://assets/models/anims/mixamo.res"):
			_lib3 = load("res://assets/models/anims/mixamo.res")
	return [_lib1, _lib2, _lib3]

func _ready() -> void:
	var path := model_path(look.get("model", ""))
	if path != "":
		_build_vrm(path)
	else:
		_build()

# ------------------------------------------------------------- external models
## A complete rigged character: VRoid/VRM (assets/models/vrm/<name>.glb,
## exported as VRM 1.0 and renamed) or a Mixamo-rigged model, e.g. from Meshy
## (assets/models/chars/<name>.fbx). The Quaternius rig still runs every clip
## invisibly; each frame its pose is copied onto the model's skeleton (global
## rest-delta), so all clips, overrides, layers and fight timing are unchanged.
const VRM_DIR := "res://assets/models/vrm/"
const CHAR_DIR := "res://assets/models/chars/"
const MIXAMO_MAP := {
	"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2",
	"neck_01": "Neck", "Head": "Head",
	"clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm", "hand_l": "LeftHand",
	"clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm", "hand_r": "RightHand",
	"thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
	"thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase",
}
var _vmap := {}                  # Quaternius bone -> bone name on the visible skeleton

static func model_path(model: String) -> String:
	if model == "":
		return ""
	for p in [CHAR_DIR + model + ".fbx", CHAR_DIR + model + ".glb", VRM_DIR + model + ".glb"]:
		if ResourceLoader.exists(p):
			return p
	return ""

func _find_vbone(ub: String) -> String:
	var cands := [VRM_MAP.get(ub, "")]
	if MIXAMO_MAP.has(ub):
		for pre in ["mixamorig_", "mixamorig:", "mixamorig1_", "mixamorig1:", ""]:
			cands.append(pre + MIXAMO_MAP[ub])
	for c in cands:
		if c != "" and vskel.find_bone(c) >= 0:
			return c
	return ""
const VRM_MAP := {
	"pelvis": "J_Bip_C_Hips", "spine_01": "J_Bip_C_Spine", "spine_02": "J_Bip_C_Chest", "spine_03": "J_Bip_C_UpperChest",
	"neck_01": "J_Bip_C_Neck", "Head": "J_Bip_C_Head",
	"clavicle_l": "J_Bip_L_Shoulder", "upperarm_l": "J_Bip_L_UpperArm", "lowerarm_l": "J_Bip_L_LowerArm", "hand_l": "J_Bip_L_Hand",
	"clavicle_r": "J_Bip_R_Shoulder", "upperarm_r": "J_Bip_R_UpperArm", "lowerarm_r": "J_Bip_R_LowerArm", "hand_r": "J_Bip_R_Hand",
	"thigh_l": "J_Bip_L_UpperLeg", "calf_l": "J_Bip_L_LowerLeg", "foot_l": "J_Bip_L_Foot", "ball_l": "J_Bip_L_ToeBase",
	"thigh_r": "J_Bip_R_UpperLeg", "calf_r": "J_Bip_R_LowerLeg", "foot_r": "J_Bip_R_Foot", "ball_r": "J_Bip_R_ToeBase",
}
## Facial expressions -> VRoid blend shapes
const EXPR := {
	"hurt": {"Fcl_BRW_Sorrow": 0.8, "Fcl_EYE_Close": 0.65, "Fcl_MTH_Large": 0.35},
	"ko": {"Fcl_EYE_Close": 1.0, "Fcl_MTH_Small": 0.5},
	"attack": {"Fcl_BRW_Angry": 0.9, "Fcl_EYE_Angry": 0.5, "Fcl_MTH_Angry": 0.4},
	"win": {"Fcl_ALL_Joy": 0.85},
}
const VRM_LIT := 0.45
const BAKED_LIT := 0.6
var vskel: Skeleton3D            # the visible skeleton (== skel for Quaternius models)
var _rt: Array = []              # [ue bone, vrm bone, ue rest^-1, vrm rest] parents first
var _hip_ue := -1
var _hip_v := -1
var _hip_ratio := 1.0
var _face: MeshInstance3D
var expr := ""                   # set each frame by the view
var _expr_w := {}                # blend shape index -> current weight
var _blink_t := 0.0

func _build_vrm(path: String) -> void:
	# invisible animation driver
	root = load(OUTFIT_DIR + "Female_Peasant.gltf").instantiate()
	add_child(root)
	skel = root.get_node("Armature/Skeleton3D")
	for m in skel.get_children():
		if m is MeshInstance3D:
			skel.remove_child(m)
			m.free()
	var v: Node3D = load(path).instantiate()
	for a in v.find_children("*", "AnimationPlayer", true, false):
		a.get_parent().remove_child(a)
		a.free()
	add_child(v)
	vskel = v.find_children("*", "Skeleton3D", true, false)[0]
	var order := []
	for ub in VRM_MAP:
		var vb := _find_vbone(ub)
		if vb == "":
			continue
		_vmap[ub] = vb
		var ui := skel.find_bone(ub)
		var vi := vskel.find_bone(vb)
		if ui < 0:
			continue
		var depth := 0
		var p := vi
		while p >= 0:
			p = vskel.get_bone_parent(p)
			depth += 1
		order.append([depth, ui, vi, skel.get_bone_global_rest(ui).basis.orthonormalized().inverse(), vskel.get_bone_global_rest(vi).basis.orthonormalized()])
	order.sort_custom(func(a, b): return a[0] < b[0])
	for o in order:
		_rt.append(o.slice(1))
	_hip_ue = skel.find_bone("pelvis")
	_hip_v = vskel.find_bone(_vmap.get("pelvis", ""))
	_hip_ratio = vskel.get_bone_global_rest(_hip_v).origin.y / maxf(0.01, skel.get_bone_global_rest(_hip_ue).origin.y)
	for m in vskel.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if String(mi.name) == "Face":
			_face = mi
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if src == null:
				continue
			var nm := src.duplicate() as StandardMaterial3D
			if src.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				# VRM MToon imports unshaded: re-light as toon so arena lights
				# read; the pale skin clips to white without the albedo scale
				nm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				nm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				nm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				nm.roughness = 1.0
				nm.albedo_color = src.albedo_color * Color(VRM_LIT, VRM_LIT, VRM_LIT)
			else:
				# baked-texture models (Meshy): matte, keep their painted light
				nm.roughness = 0.9
				nm.albedo_color = src.albedo_color * Color(BAKED_LIT, BAKED_LIT, BAKED_LIT)
				nm.metallic = 0.0
				nm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			mi.set_surface_override_material(s, nm)
			_tinted.append(nm)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var hsc: float = look.get("height", 1.0)
	scale = Vector3(hsc, hsc, hsc)
	_stylise(vskel)
	_weapons_and_anim()

func _retarget() -> void:
	for e in _rt:
		var gt: Basis = skel.get_bone_global_pose(e[0]).basis.orthonormalized() * e[2] * e[3]
		var pi := vskel.get_bone_parent(e[1])
		var pg := vskel.get_bone_global_pose(pi).basis.orthonormalized() if pi >= 0 else Basis.IDENTITY
		vskel.set_bone_pose_rotation(e[1], (pg.inverse() * gt).get_rotation_quaternion())
	var d := skel.get_bone_global_pose(_hip_ue).origin - skel.get_bone_global_rest(_hip_ue).origin
	var hp := vskel.get_bone_parent(_hip_v)
	var pgb := vskel.get_bone_global_pose(hp).basis.orthonormalized() if hp >= 0 else Basis.IDENTITY
	vskel.set_bone_pose_position(_hip_v, vskel.get_bone_rest(_hip_v).origin + pgb.inverse() * (d * _hip_ratio))

func _update_face(delta: float) -> void:
	var want := {}
	for k in EXPR.get(expr, {}):
		want[k] = EXPR[expr][k]
	# idle blinking
	_blink_t += delta
	if expr == "" and fmod(_blink_t, 3.7) < 0.12:
		want["Fcl_EYE_Close"] = 1.0
	for k in want:
		var i := _face.find_blend_shape_by_name(k)
		if i >= 0 and not _expr_w.has(i):
			_expr_w[i] = 0.0
	for i in _expr_w.keys():
		var target: float = want.get(String(_face.mesh.get_blend_shape_name(i)), 0.0)
		_expr_w[i] = move_toward(_expr_w[i], target, delta * 9.0)
		_face.set_blend_shape_value(i, _expr_w[i])

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
	var src_mat := (hd.mesh as Mesh).surface_get_material(0) as StandardMaterial3D
	var lip_rect := Vector4(0.184, 0.262, 0.036, 0.013) if female else Vector4(0.186, 0.266, 0.033, 0.011)
	head.set_surface_override_material(0, _skin_mat(src_mat, look.get("lip_amt", 0.0), lip_rect))
	for part in hd.extras:
		var nm := String(part.name)
		if nm == "Eyebrows":
			continue
		var e := MeshInstance3D.new()
		e.mesh = part.mesh
		e.skin = part.skin
		skel.add_child(e)
		e.skeleton = NodePath("..")
		if nm == "Eyes":
			var em := ShaderMaterial.new()
			em.shader = preload("res://assets/shaders/eye.gdshader")
			em.set_shader_parameter("tex", ((part.mesh as Mesh).surface_get_material(0) as StandardMaterial3D).albedo_texture)
			em.set_shader_parameter("iris", look.get("eye", Color(0.12, 0.07, 0.04)))
			e.set_surface_override_material(0, em)
			_shaders.append(em)
	var brow := int(look.get("brow", 1 if female else 0))
	_attach_hair("Eyebrows_Female" if brow == 1 else "Eyebrows_Regular")
	# hair: explicit hair_style (player appearance) or derived from the sect look
	var hs: String = look.get("head_style", "bun")
	var acc: String = look.get("acc", hs)
	var style: String = look.get("hair_style", "")
	if style == "":
		match hs:
			"bun", "crown", "hat": style = "bun"
			"long": style = "long"
			"headband", "wild": style = "headband"
			"bald": style = "bald"
			"hood": style = "bald" if outfit == "Ranger" else "buzz"
	var hood_on := acc == "hood" and outfit == "Ranger"
	var hair := ""
	match style:
		"bun": hair = "Hair_Buns"
		"long": hair = "Hair_Long"
		"headband": hair = "Hair_SimpleParted"
		"buzz": hair = "Hair_BuzzedFemale" if female else "Hair_Buzzed"
	if hood_on and hair in ["Hair_Buns", "Hair_Long"]:
		hair = "Hair_BuzzedFemale" if female else "Hair_Buzzed"
	if hair != "":
		_attach_hair(hair)
	if look.get("beard", false):
		_attach_hair("Hair_Beard")
	var hsc: float = look.get("height", 1.0)
	scale = Vector3(hsc, hsc, hsc)
	_face_scale = Appearance.FACE_SCALE[clampi(int(look.get("face", 0)), 0, Appearance.FACE_SCALE.size() - 1)]
	# code-drawn extras (sash, headband, hats, beads, robe skirt) removed: real models only
	_stylise(skel)
	vskel = skel
	_weapons_and_anim()
	for mi in skel.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _weapons_and_anim() -> void:
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
	if L[2] != null:
		ap.add_animation_library("m", L[2])
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _tint(mi: MeshInstance3D, col: Color) -> void:
	for s in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(s) as StandardMaterial3D
		if m == null:
			continue
		var nm := m.duplicate() as StandardMaterial3D
		var name := m.resource_name
		if name.contains("Regular") or name.contains("Superhero"):
			mi.set_surface_override_material(s, _skin_mat(m, 0.0, Vector4(0, 0, 0.001, 0.001)))
			continue
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
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skel.add_child(mi)
		mi.skeleton = NodePath("..")
		_hair_mat(mi)
	h.free()

## Node following a (Quaternius-named) bone on the visible skeleton. On VRM
## models it carries the Quaternius bone's rest frame, so grips and markers
## made for that rig line up unchanged.
func _bone_att(bone: String) -> Node3D:
	var b := BoneAttachment3D.new()
	if vskel == skel:
		b.bone_name = bone
		skel.add_child(b)
		return b
	var vb: String = _vmap.get(bone, _vmap.get("pelvis", ""))
	b.bone_name = vb
	vskel.add_child(b)
	var fr := Node3D.new()
	fr.basis = vskel.get_bone_global_rest(vskel.find_bone(vb)).basis.orthonormalized().inverse() * skel.get_bone_global_rest(skel.find_bone(bone)).basis.orthonormalized()
	b.add_child(fr)
	return fr

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
			Weapons.seg(head, Weapons.cyl(0.112, 0.112, 0.03, 18), _mat(trim), Vector3(0, 0.155, -0.015))
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

func _apply_layer() -> void:
	var la := ap.get_animation(layer.clip)
	if la == null:
		return
	var t := clampf(float(layer.t), 0.0, la.length)
	for bn in layer.bones:
		var bi := skel.find_bone(bn)
		if bi < 0:
			continue
		for tr in la.get_track_count():
			if la.track_get_type(tr) == Animation.TYPE_ROTATION_3D and String(la.track_get_path(tr)).ends_with(":" + bn):
				skel.set_bone_pose_rotation(bi, la.rotation_track_interpolate(tr, t))
				break

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
	if not layer.is_empty():
		_apply_layer()
	for bn in overrides:
		var bi := skel.find_bone(bn)
		if bi >= 0:
			skel.set_bone_pose_rotation(bi, skel.get_bone_pose_rotation(bi) * (overrides[bn] as Quaternion))
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
	if _head_bone < 0:
		_head_bone = skel.find_bone("Head")
	if _face_scale != Vector3.ONE and _head_bone >= 0:
		skel.set_bone_pose_scale(_head_bone, _face_scale)
	if vskel != skel and vskel != null:
		_retarget()
		if _face:
			_update_face(delta)
	for sm in _shaders:
		sm.set_shader_parameter("flash", Vector3.ONE * _flash * 0.6)
	for m in _tinted:
		m.emission_enabled = _flash > 0.0
		if _flash > 0.0:
			m.emission = Color(1, 0.95, 0.85) * (_flash * 0.7)

func _skin_mat(src: StandardMaterial3D, lip_amt: float, lip_rect: Vector4) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://assets/shaders/skin.gdshader")
	sm.set_shader_parameter("tex", src.albedo_texture)
	sm.set_shader_parameter("nrm", src.normal_texture)
	sm.set_shader_parameter("skin_tone", look.get("skin_tone", Color(0.93, 0.76, 0.62)))
	sm.set_shader_parameter("lip_color", look.get("lip", Color(0.72, 0.32, 0.3)))
	sm.set_shader_parameter("lip_amt", lip_amt)
	sm.set_shader_parameter("lip_rect", lip_rect)
	_shaders.append(sm)
	return sm

static var _outline: ShaderMaterial

## Ink outline + rim light on every character surface (not eyes/brows).
func _stylise(sk: Skeleton3D) -> void:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = preload("res://assets/shaders/outline.gdshader")
	var ow: float = look.get("outline", 0.007)
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var nm := String(m3.name)
		if nm.begins_with("Eye") or not m3.visible:
			continue
		for s in m3.mesh.get_surface_count():
			var mat := m3.get_surface_override_material(s)
			if mat == null:
				mat = m3.mesh.surface_get_material(s)
				if mat == null:
					continue
				mat = mat.duplicate()
				m3.set_surface_override_material(s, mat)
			if mat is StandardMaterial3D:
				var sm := mat as StandardMaterial3D
				sm.rim_enabled = true
				sm.rim = 0.3
				sm.rim_tint = 0.35
			if ow > 0.0 and not nm.begins_with("Hair_B") and mat.next_pass == null:
				mat.next_pass = _outline

## True if a "lib/clip" name exists in the loaded libraries.
static func has_clip(name: String) -> bool:
	var L := libs()
	var p := name.split("/")
	if p.size() != 2:
		return false
	var lib: AnimationLibrary = L[0] if p[0] == "a" else (L[1] if p[0] == "b" else L[2])
	return lib != null and lib.has_animation(p[1])
