class_name Robe
extends MeshInstance3D
## Verlet-simulated robe skirt: four flaps (front, back, left, right) hanging
## from the pelvis, pushed by gravity, inertia and the leg bones.

const SEGS := 7
const GRAV := Vector3(0, -9.8, 0)

var skel: Skeleton3D
var length := 0.55
var col := Color(0.4, 0.5, 0.7)
var trim := Color(0.9, 0.85, 0.7)
var _pelvis := -1
var _legs: Array = []          # [[bone_a, bone_b, radius], ...]
var _fwd_l := Vector3.FORWARD  # pelvis-local axes for model forward / up
var _up_l := Vector3.UP
var _flaps: Array = []         # each: {pts, prev, off(fwd, side, up), side_dir, width}
var _im: ImmediateMesh
var _ready_sim := false
var _last_o := Vector3.ZERO

func setup(p_skel: Skeleton3D, p_len: float, p_col: Color, p_trim: Color) -> void:
	skel = p_skel
	length = p_len
	col = p_col
	trim = p_trim

func _ready() -> void:
	top_level = true
	_im = ImmediateMesh.new()
	mesh = _im
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.8
	m.rim_enabled = true
	m.rim = 0.3
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_pelvis = skel.find_bone("pelvis")
	for pair in [["thigh_l", "calf_l", 0.095], ["calf_l", "foot_l", 0.065], ["thigh_r", "calf_r", 0.095], ["calf_r", "foot_r", 0.065]]:
		_legs.append([skel.find_bone(pair[0]), skel.find_bone(pair[1]), pair[2]])
	# calibrate pelvis axes against the model's forward (+Z) and up (+Y) in rest pose
	var rb := skel.get_bone_global_rest(_pelvis).basis.orthonormalized()
	_fwd_l = rb.inverse() * Vector3(0, 0, 1)
	_up_l = rb.inverse() * Vector3(0, 1, 0)
	# front, back, left, right: offset along (fwd, side) and flap width
	for spec in [[0.12, 0.0, 0.26], [-0.12, 0.0, 0.3], [0.0, 0.16, 0.16], [0.0, -0.16, 0.16]]:
		_flaps.append({"pts": [], "prev": [], "f": spec[0], "s": spec[1], "w": spec[2]})

func _frame() -> Dictionary:
	var gp := skel.global_transform * skel.get_bone_global_pose(_pelvis)
	var b := gp.basis.orthonormalized()
	var fwd := (b * _fwd_l).normalized()
	var up := (b * _up_l).normalized()
	var side := up.cross(fwd).normalized()
	return {"o": gp.origin, "f": fwd, "u": up, "s": side}

func _anchor(fr: Dictionary, fl: Dictionary) -> Vector3:
	return fr.o + fr.f * float(fl.f) + fr.s * float(fl.s) + fr.u * 0.05

func _init_pts(fr: Dictionary) -> void:
	var seg := length / SEGS
	for fl in _flaps:
		var a := _anchor(fr, fl)
		var pts := []
		for i in SEGS + 1:
			pts.append(a + Vector3(0, -seg * i, 0) + (fr.f * float(fl.f) + fr.s * float(fl.s)) * 0.2 * i / SEGS)
		fl.pts = pts
		fl.prev = pts.duplicate()
	_ready_sim = true

func _process(delta: float) -> void:
	if skel == null or not is_visible_in_tree():
		return
	var fr := _frame()
	var dt := clampf(delta, 0.001, 0.05)
	var seg := length / SEGS
	var bp := func(name_i: int) -> Vector3: return (skel.global_transform * skel.get_bone_global_pose(name_i)).origin
	var thl: Vector3 = (bp.call(_legs[0][1]) - bp.call(_legs[0][0])).normalized()
	var thr: Vector3 = (bp.call(_legs[2][1]) - bp.call(_legs[2][0])).normalized()
	var down := -fr.u as Vector3
	var vel := Vector3.ZERO
	if _ready_sim:
		vel = (fr.o - _last_o) / dt
	_last_o = fr.o
	_ready_sim = true
	for fl in _flaps:
		var f := float(fl.f)
		var s := float(fl.s)
		var target: Vector3
		if f > 0.0:
			# front: follow whichever thigh is further forward, otherwise hang
			var leg := thl if thl.dot(fr.f) > thr.dot(fr.f) else thr
			target = (down * 0.45 + leg * 0.55 + fr.f * 0.12).normalized()
		elif f < 0.0:
			var leg2 := thl if thl.dot(fr.f) < thr.dot(fr.f) else thr
			target = (down * 0.55 + leg2 * 0.45 - fr.f * 0.1).normalized()
		else:
			var leg3 := thl if s < 0.0 else thr
			var outw: Vector3 = fr.s * signf(s)
			target = (down * 0.6 + leg3 * 0.3 + outw * 0.18).normalized()
		# inertia: cloth trails behind fast movement
		target = (target - vel * 0.035).normalized()
		var cur: Vector3 = fl.get("dir", target)
		cur = cur.lerp(target, minf(1.0, dt * 12.0)).normalized()
		fl.dir = cur
		var pts := []
		var p := _anchor(fr, fl)
		pts.append(p)
		for i in SEGS:
			var t := float(i) / SEGS
			var d := cur.lerp(down, t * 0.45).normalized()
			p = p + d * seg
			pts.append(p)
		fl.pts = pts
	_draw(fr)

static func _closest(a: Vector3, b: Vector3, p: Vector3) -> Vector3:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return a + ab * t

func _draw(fr: Dictionary) -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for fl in _flaps:
		var pts: Array = fl.pts
		var wdir: Vector3 = fr.s if absf(float(fl.f)) > 0.0 else fr.f
		var w0: float = fl.w * 0.5
		for i in range(pts.size() - 1):
			var t0 := float(i) / (pts.size() - 1)
			var t1 := float(i + 1) / (pts.size() - 1)
			var wa := w0 * (1.0 + t0 * 0.35)
			var wb := w0 * (1.0 + t1 * 0.35)
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[i + 1]
			var c0 := col if i < pts.size() - 2 else col
			var c1 := trim if i == pts.size() - 2 else col.darkened(t1 * 0.15)
			var n := (p1 - p0).cross(wdir).normalized()
			var v := [p0 - wdir * wa, p0 + wdir * wa, p1 - wdir * wb, p1 + wdir * wb]
			var cs := [c0, c0, c1, c1]
			for k in [0, 1, 2, 1, 3, 2]:
				_im.surface_set_color(cs[k])
				_im.surface_set_normal(n)
				_im.surface_add_vertex(v[k])
	_im.surface_end()
