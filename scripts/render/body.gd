class_name Body
extends Node3D
## Procedural low-poly wuxia fighter built from primitive meshes on a joint
## hierarchy. Model space: forward = +X, up = +Y, the figure's right = +Z.
## A rotation about a joint's Z axis by a positive angle swings the limb
## below it forward (+X); about X by a positive angle swings it toward -Z.

const JOINTS := ["pelvis", "spine", "chest", "neck", "head",
	"sh_l", "el_l", "wr_l", "sh_r", "el_r", "wr_r",
	"hip_l", "kn_l", "an_l", "hip_r", "kn_r", "an_r"]

const HIP_H := 0.95

var j: Dictionary = {}          # joint name -> Node3D
var cur: Dictionary = {}        # joint name -> Vector3 (degrees)
var root_off := Vector3.ZERO    # pelvis offset from rest
var look: Dictionary
var weapon_tip: Node3D          # marker at the weapon's striking end
var hand_r_tip: Node3D
var hand_l_tip: Node3D
var foot_r_tip: Node3D
var foot_l_tip: Node3D
var _mats: Dictionary = {}
var _flash := 0.0
var _all_mats: Array[StandardMaterial3D] = []
var ribbons: Array[Node3D] = []

func _init(lk: Dictionary = {}) -> void:
	look = lk

func _ready() -> void:
	_build()

# ---------------------------------------------------------------- materials
func mat(key: String, col: Color, rough := 0.85) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = 0.0
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	m.emission_enabled = true
	m.emission = Color.BLACK
	_mats[key] = m
	_all_mats.append(m)
	return m

func flash(amount := 1.0) -> void:
	_flash = max(_flash, amount)

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 6.0)
		var e := Color(1, 0.95, 0.85) * (_flash * 0.8)
		for m in _all_mats:
			m.emission = e
	# trailing ribbons sway
	var t := Time.get_ticks_msec() * 0.001
	for i in ribbons.size():
		var r := ribbons[i]
		r.rotation.z = -0.5 + sin(t * 5.0 + i) * 0.18
		r.rotation.x = sin(t * 3.7 + i * 1.3) * 0.15

# ---------------------------------------------------------------- building
func _seg(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = max(h, r * 2.0 + 0.001)
	c.radial_segments = 10
	c.rings = 2
	return c

func _cyl(top: float, bot: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bot
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

func _sph(r: float, h := -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0 else h
	s.radial_segments = 12
	s.rings = 6
	return s

func _joint(name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	parent.add_child(n)
	j[name] = n
	cur[name] = Vector3.ZERO
	return n

func _build() -> void:
	var skin: Color = look.get("skin", Color(0.93, 0.76, 0.6))
	var robe: Color = look.get("robe", Color(0.25, 0.35, 0.6))
	var trim: Color = look.get("trim", robe.lightened(0.45))
	var pants: Color = look.get("pants", robe.darkened(0.45))
	var boots: Color = look.get("boots", Color(0.12, 0.1, 0.09))
	var sash: Color = look.get("sash", Color(0.75, 0.15, 0.12))
	var hair: Color = look.get("hair", Color(0.08, 0.07, 0.07))
	var female: bool = look.get("female", false)
	var bulk: float = look.get("bulk", 1.0)
	var height: float = look.get("height", 1.0)
	scale = Vector3(1.0, height, 1.0)

	var m_skin := mat("skin", skin, 0.7)
	var m_robe := mat("robe", robe)
	var m_trim := mat("trim", trim)
	var m_pants := mat("pants", pants)
	var m_boot := mat("boot", boots)
	var m_sash := mat("sash", sash)
	var m_hair := mat("hair", hair, 0.6)

	var sw := 0.19 * bulk   # shoulder half width
	var pelvis := _joint("pelvis", self, Vector3(0, HIP_H, 0))
	var spine := _joint("spine", pelvis, Vector3(0, 0.06, 0))
	var chest := _joint("chest", spine, Vector3(0, 0.2, 0))
	var neck := _joint("neck", chest, Vector3(0, 0.27, 0))
	var head := _joint("head", neck, Vector3(0, 0.07, 0))

	# torso: belly + chest + robe overlap (front lapel)
	_seg(pelvis, _cyl(0.15 * bulk, 0.17 * bulk, 0.18), m_robe, Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1.0, 1, 0.8))
	_seg(spine, _cyl(0.16 * bulk, 0.15 * bulk, 0.22), m_robe, Vector3(0, 0.1, 0), Vector3.ZERO, Vector3(1.0, 1, 0.82))
	var chest_w := (0.21 if not female else 0.17) * bulk
	_seg(chest, _cyl(chest_w, 0.16 * bulk, 0.28), m_robe, Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(0.85, 1, 1.0))
	# collar / lapel cross
	_seg(chest, _box(0.04, 0.3, 0.05), m_trim, Vector3(0.155 * bulk, 0.1, 0.03), Vector3(25, 0, 0))
	_seg(chest, _box(0.04, 0.3, 0.05), m_trim, Vector3(0.16 * bulk, 0.1, -0.03), Vector3(-25, 0, 0))
	if look.get("bare_chest", false):
		_seg(chest, _box(0.02, 0.18, 0.14), m_skin, Vector3(0.17 * bulk, 0.18, 0))
	# sash
	_seg(spine, _cyl(0.17 * bulk, 0.17 * bulk, 0.07), m_sash, Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1.0, 1, 0.84))
	var rib := Node3D.new()
	rib.position = Vector3(-0.12 * bulk, -0.01, 0.06)
	spine.add_child(rib)
	_seg(rib, _box(0.05, 0.32, 0.015), m_sash, Vector3(-0.02, -0.16, 0))
	ribbons.append(rib)
	var rib2 := Node3D.new()
	rib2.position = Vector3(-0.12 * bulk, -0.01, -0.05)
	spine.add_child(rib2)
	_seg(rib2, _box(0.05, 0.26, 0.015), m_sash, Vector3(-0.02, -0.13, 0))
	ribbons.append(rib2)

	# neck + head
	_seg(neck, _cyl(0.05, 0.055, 0.1), m_skin, Vector3(0, 0.03, 0))
	_seg(head, _sph(0.115, 0.26), m_skin, Vector3(0.01, 0.12, 0))
	# eyes / brows (face looks toward +X)
	var m_eye := mat("eye", Color(0.05, 0.04, 0.04), 0.4)
	for side in [-1.0, 1.0]:
		_seg(head, _box(0.012, 0.022, 0.03), m_eye, Vector3(0.11, 0.14, 0.042 * side))
		_seg(head, _box(0.012, 0.012, 0.045), m_hair, Vector3(0.112, 0.172, 0.045 * side), Vector3(18.0 * side, 0, 0))
	_seg(head, _box(0.03, 0.04, 0.025), m_skin, Vector3(0.12, 0.105, 0))   # nose
	_build_head_style(head, m_hair, m_trim, m_robe, skin)
	if look.get("beard", false):
		_seg(head, _cyl(0.01, 0.06, 0.16, 6), m_hair, Vector3(0.08, -0.0, 0), Vector3(0, 0, 165))

	# arms
	for side in ["l", "r"]:
		var sz := sw if side == "r" else -sw
		var sh := _joint("sh_" + side, chest, Vector3(0, 0.23, sz))
		_seg(sh, _sph(0.075 * bulk), m_robe, Vector3.ZERO)
		_seg(sh, _cyl(0.07 * bulk, 0.06 * bulk, 0.29), m_robe, Vector3(0, -0.14, 0))
		var el := _joint("el_" + side, sh, Vector3(0, -0.29, 0))
		_seg(el, _cap(0.045 * bulk, 0.25), m_skin, Vector3(0, -0.12, 0))
		# wide wuxia sleeve (bell)
		_seg(el, _cyl(0.06 * bulk, 0.105 * bulk, 0.2, 10), m_robe, Vector3(0, -0.08, 0))
		_seg(el, _cyl(0.106 * bulk, 0.108 * bulk, 0.025, 10), m_trim, Vector3(0, -0.185, 0))
		if look.get("bracers", false):
			_seg(el, _cyl(0.05, 0.05, 0.1), m_boot, Vector3(0, -0.2, 0))
		var wr := _joint("wr_" + side, el, Vector3(0, -0.26, 0))
		_seg(wr, _box(0.07, 0.1, 0.05), m_skin, Vector3(0.0, -0.045, 0))
		var tip := Node3D.new()
		tip.position = Vector3(0, -0.09, 0)
		wr.add_child(tip)
		if side == "r":
			hand_r_tip = tip
		else:
			hand_l_tip = tip

	# legs
	for side in ["l", "r"]:
		var hz := 0.095 * bulk * (1.0 if side == "r" else -1.0)
		var hp := _joint("hip_" + side, pelvis, Vector3(0, -0.04, hz))
		_seg(hp, _cyl(0.085 * bulk, 0.065, 0.44), m_pants, Vector3(0, -0.21, 0))
		var kn := _joint("kn_" + side, hp, Vector3(0, -0.44, 0))
		_seg(kn, _cyl(0.062, 0.05, 0.42), m_pants, Vector3(0, -0.2, 0))
		_seg(kn, _cyl(0.058, 0.064, 0.2), m_boot, Vector3(0, -0.33, 0))   # boot shaft
		var an := _joint("an_" + side, kn, Vector3(0, -0.43, 0))
		_seg(an, _box(0.24, 0.07, 0.09), m_boot, Vector3(0.05, -0.035, 0))
		var ft := Node3D.new()
		ft.position = Vector3(0.15, -0.03, 0)
		an.add_child(ft)
		if side == "r":
			foot_r_tip = ft
		else:
			foot_l_tip = ft
		# robe flaps that follow the thigh (split robe so kicks read clearly)
		var flap_len: float = look.get("robe_len", 0.5)
		_seg(hp, _box(0.2, flap_len, 0.11), m_robe, Vector3(0.0, -flap_len * 0.5 + 0.04, hz * 0.25))
		_seg(hp, _box(0.205, 0.03, 0.115), m_trim, Vector3(0.0, -flap_len + 0.05, hz * 0.25))

	_build_weapon(j["wr_r"], j["wr_l"])

	for n in JOINTS:
		cur[n] = Vector3.ZERO

func _build_head_style(head: Node3D, m_hair: Material, m_trim: Material, m_robe: Material, skin: Color) -> void:
	var style: String = look.get("head_style", "bun")
	match style:
		"bald":
			# shaved head + ordination dots
			var m_dot := mat("dot", skin.darkened(0.35))
			for i in 3:
				_seg(head, _sph(0.01), m_dot, Vector3(-0.02 + i * 0.03, 0.245, 0))
		"bun":
			_seg(head, _sph(0.12, 0.2), m_hair, Vector3(-0.015, 0.155, 0))
			_seg(head, _sph(0.055), m_hair, Vector3(-0.02, 0.27, 0))
			_seg(head, _cyl(0.03, 0.035, 0.03), m_trim, Vector3(-0.02, 0.3, 0))
			_seg(head, _box(0.012, 0.012, 0.12), m_trim, Vector3(-0.02, 0.29, 0))   # hairpin
		"long":
			_seg(head, _sph(0.125, 0.21), m_hair, Vector3(-0.015, 0.15, 0))
			_seg(head, _box(0.06, 0.42, 0.18), m_hair, Vector3(-0.09, -0.07, 0), Vector3(0, 0, -8))
			_seg(head, _sph(0.05), m_hair, Vector3(-0.05, 0.27, 0))
			_seg(head, _box(0.01, 0.03, 0.1), m_trim, Vector3(-0.05, 0.3, 0))
		"headband":
			_seg(head, _sph(0.125, 0.22), m_hair, Vector3(-0.02, 0.15, 0))
			_seg(head, _cyl(0.122, 0.122, 0.035), m_trim, Vector3(0.0, 0.18, 0))
			var tail := Node3D.new()
			tail.position = Vector3(-0.12, 0.18, 0)
			head.add_child(tail)
			_seg(tail, _box(0.03, 0.26, 0.015), m_trim, Vector3(0, -0.13, 0.02))
			ribbons.append(tail)
		"hood":
			_seg(head, _sph(0.135, 0.27), m_robe, Vector3(-0.02, 0.13, 0))
			_seg(head, _box(0.03, 0.08, 0.2), mat("mask", Color(0.1, 0.1, 0.12)), Vector3(0.115, 0.08, 0))
		"hat":
			_seg(head, _sph(0.12, 0.2), m_hair, Vector3(-0.015, 0.15, 0))
			_seg(head, _cyl(0.02, 0.32, 0.12, 14), mat("straw", Color(0.78, 0.66, 0.42)), Vector3(0, 0.29, 0))
		"crown":
			_seg(head, _sph(0.122, 0.21), m_hair, Vector3(-0.015, 0.15, 0))
			_seg(head, _box(0.1, 0.07, 0.05), mat("gold", Color(0.85, 0.66, 0.2), 0.35), Vector3(-0.0, 0.28, 0))
		"wild":
			_seg(head, _sph(0.13, 0.24), m_hair, Vector3(-0.02, 0.15, 0))
			for i in 5:
				_seg(head, _cyl(0.0, 0.04, 0.16, 5), m_hair, Vector3(-0.05 - i * 0.015, 0.2, -0.08 + i * 0.04), Vector3(0, 0, 60 + i * 5))

func _build_weapon(wr: Node3D, wl: Node3D) -> void:
	var w: String = look.get("weapon", "none")
	var m_steel := mat("steel", Color(0.82, 0.85, 0.9), 0.25)
	m_steel.metallic = 0.6
	var m_wood := mat("wood", Color(0.45, 0.28, 0.14))
	var m_gold := mat("gold", Color(0.85, 0.66, 0.2), 0.35)
	var m_grip := mat("grip", Color(0.25, 0.08, 0.06))
	weapon_tip = Node3D.new()
	match w:
		"sword":
			# held in the fist, blade along the hand's -Y extended past the fist
			var g := Node3D.new()
			g.position = Vector3(0.0, -0.06, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.018, 0.018, 0.16), m_grip, Vector3(0, 0.0, 0))
			_seg(g, _box(0.05, 0.025, 0.16), m_gold, Vector3(0, -0.085, 0))
			_seg(g, _box(0.05, 0.75, 0.012), m_steel, Vector3(0, -0.47, 0))
			_seg(g, _box(0.035, 0.06, 0.012), m_steel, Vector3(0, -0.865, 0), Vector3(0, 0, 45))
			_seg(g, _box(0.02, 0.15, 0.01), mat("tassel", Color(0.8, 0.1, 0.1)), Vector3(0, 0.15, 0))
			weapon_tip.position = Vector3(0, -0.88, 0)
			g.add_child(weapon_tip)
		"saber":
			var g := Node3D.new()
			g.position = Vector3(0.0, -0.06, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.02, 0.02, 0.17), m_grip, Vector3.ZERO)
			_seg(g, _cyl(0.05, 0.05, 0.02, 10), m_gold, Vector3(0, -0.09, 0))
			_seg(g, _box(0.09, 0.7, 0.012), m_steel, Vector3(0.02, -0.44, 0), Vector3(0, 0, -4))
			weapon_tip.position = Vector3(0.04, -0.8, 0)
			g.add_child(weapon_tip)
		"staff":
			var g := Node3D.new()
			g.position = Vector3(0, -0.05, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.024, 0.024, 1.75), m_wood, Vector3(0, -0.3, 0))
			_seg(g, _cyl(0.03, 0.03, 0.08), m_gold, Vector3(0, -1.15, 0))
			_seg(g, _cyl(0.03, 0.03, 0.08), m_gold, Vector3(0, 0.55, 0))
			weapon_tip.position = Vector3(0, -1.17, 0)
			g.add_child(weapon_tip)
		"spear":
			var g := Node3D.new()
			g.position = Vector3(0, -0.05, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.02, 0.02, 1.9), m_wood, Vector3(0, -0.35, 0))
			_seg(g, _cyl(0.0, 0.04, 0.24, 6), m_steel, Vector3(0, -1.42, 0), Vector3(180, 0, 0))
			_seg(g, _sph(0.05), mat("tassel", Color(0.8, 0.1, 0.1)), Vector3(0, -1.27, 0))
			weapon_tip.position = Vector3(0, -1.54, 0)
			g.add_child(weapon_tip)
		"dual":
			for wrist in [wr, wl]:
				var g := Node3D.new()
				g.position = Vector3(0.0, -0.06, 0)
				wrist.add_child(g)
				_seg(g, _cyl(0.016, 0.016, 0.12), m_grip, Vector3.ZERO)
				_seg(g, _box(0.04, 0.02, 0.1), m_gold, Vector3(0, -0.065, 0))
				_seg(g, _box(0.04, 0.5, 0.01), m_steel, Vector3(0, -0.32, 0))
				if wrist == wr:
					weapon_tip.position = Vector3(0, -0.57, 0)
					g.add_child(weapon_tip)
		"daggers":
			var g := Node3D.new()
			g.position = Vector3(0.0, -0.06, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.015, 0.015, 0.1), m_grip, Vector3.ZERO)
			_seg(g, _box(0.035, 0.26, 0.01), m_steel, Vector3(0, -0.18, 0))
			weapon_tip.position = Vector3(0, -0.31, 0)
			g.add_child(weapon_tip)
			# dagger belt
			var belt := j["spine"] as Node3D
			for i in 4:
				_seg(belt, _box(0.02, 0.12, 0.01), m_steel, Vector3(-0.05 + i * 0.05, -0.03, 0.17), Vector3(0, 0, 10))
		"fan":
			var g := Node3D.new()
			g.position = Vector3(0.0, -0.08, 0)
			wr.add_child(g)
			_seg(g, _cyl(0.02, 0.24, 0.012, 7), mat("paper", Color(0.95, 0.92, 0.82)), Vector3(0, -0.12, 0), Vector3(90, 0, 0), Vector3(1, 1, 1))
			weapon_tip.position = Vector3(0, -0.3, 0)
			g.add_child(weapon_tip)
		_:
			weapon_tip.position = Vector3(0, -0.1, 0)
			wr.add_child(weapon_tip)
	if look.get("beads", false):
		var chest := j["chest"] as Node3D
		var m_bead := mat("bead", Color(0.35, 0.15, 0.08), 0.4)
		for i in 12:
			var a := float(i) / 12.0 * TAU
			_seg(chest, _sph(0.022), m_bead, Vector3(0.12 + cos(a) * 0.08, 0.2 + sin(a) * 0.1, sin(a) * 0.15 * 0.0 + cos(a) * 0.02))

# ---------------------------------------------------------------- posing
## Apply a pose immediately (dict joint -> Vector3 degrees, optional "root").
func apply_pose(p: Dictionary) -> void:
	for n in JOINTS:
		var v: Vector3 = p.get(n, Vector3.ZERO)
		cur[n] = v
		(j[n] as Node3D).rotation_degrees = v
	root_off = p.get("root", Vector3.ZERO)
	(j["pelvis"] as Node3D).position = Vector3(0, HIP_H, 0) + root_off

## Blend current pose toward target by factor k (0..1).
func blend_to(p: Dictionary, k: float) -> void:
	for n in JOINTS:
		var v: Vector3 = p.get(n, Vector3.ZERO)
		var c: Vector3 = cur[n]
		c = c.lerp(v, k)
		cur[n] = c
		(j[n] as Node3D).rotation_degrees = c
	var ro: Vector3 = p.get("root", Vector3.ZERO)
	root_off = root_off.lerp(ro, k)
	(j["pelvis"] as Node3D).position = Vector3(0, HIP_H, 0) + root_off

static func mix(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for n in JOINTS:
		out[n] = (a.get(n, Vector3.ZERO) as Vector3).lerp(b.get(n, Vector3.ZERO), t)
	out["root"] = (a.get("root", Vector3.ZERO) as Vector3).lerp(b.get("root", Vector3.ZERO), t)
	return out
