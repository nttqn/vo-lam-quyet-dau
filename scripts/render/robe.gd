class_name Robe
extends MeshInstance3D
## Continuous robe skirt: a ring of cloth columns around the waist. Each
## column hangs toward gravity, is pulled along by the nearer thigh (so kicks
## lift the hem), trails behind fast movement and flares slightly outward.

const COLS := 14
const SEGS := 6

var skel: Skeleton3D
var length := 0.62
var col := Color(0.4, 0.5, 0.7)
var trim := Color(0.9, 0.85, 0.7)
var _pelvis := -1
var _thigh := [-1, -1]
var _calf := [-1, -1]
var _fwd_l := Vector3.FORWARD
var _up_l := Vector3.UP
var _dirs: Array = []          # smoothed hang direction per column
var _im: ImmediateMesh
var _last_o := Vector3.ZERO
var _have_last := false

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
	m.roughness = 0.85
	m.rim_enabled = true
	m.rim = 0.25
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_pelvis = skel.find_bone("pelvis")
	_thigh = [skel.find_bone("thigh_l"), skel.find_bone("thigh_r")]
	_calf = [skel.find_bone("calf_l"), skel.find_bone("calf_r")]
	var rb := skel.get_bone_global_rest(_pelvis).basis.orthonormalized()
	_fwd_l = rb.inverse() * Vector3(0, 0, 1)
	_up_l = rb.inverse() * Vector3(0, 1, 0)
	_dirs.resize(COLS)

func _gpos(bone: int) -> Vector3:
	return (skel.global_transform * skel.get_bone_global_pose(bone)).origin

func _process(delta: float) -> void:
	if skel == null or not is_visible_in_tree():
		return
	var dt := clampf(delta, 0.001, 0.05)
	var gp := skel.global_transform * skel.get_bone_global_pose(_pelvis)
	var b := gp.basis.orthonormalized()
	var sc := skel.global_transform.basis.get_scale().x
	var fwd := (b * _fwd_l).normalized()
	var up := (b * _up_l).normalized()
	var side := up.cross(fwd).normalized()
	var down := -up
	var center := gp.origin + up * 0.1 * sc
	var vel := Vector3.ZERO
	if _have_last:
		vel = (gp.origin - _last_o) / dt
	_last_o = gp.origin
	_have_last = true
	var legs := []
	for k in 2:
		var hip := _gpos(_thigh[k])
		var knee := _gpos(_calf[k])
		legs.append([hip, (knee - hip).normalized()])
	var seg := length * sc / SEGS
	var grid := []
	for c in COLS:
		var th := TAU * float(c) / COLS
		var radial := (fwd * cos(th) + side * sin(th)).normalized()
		var anchor := center + (fwd * cos(th) * 0.13 + side * sin(th) * 0.17) * sc
		var best := 0.0
		var leg_dir := down
		for lg in legs:
			var to_leg: Vector3 = (lg[0] - gp.origin)
			to_leg -= up * to_leg.dot(up)
			var w := clampf(0.55 + radial.dot(to_leg.normalized()) * 0.6, 0.0, 1.0)
			w = maxf(w, clampf(radial.dot(lg[1]) * 1.2, 0.0, 1.0))
			if w > best:
				best = w
				leg_dir = lg[1]
		var target := (down * (1.0 - best * 0.6) + leg_dir * best * 0.6 + radial * 0.22).normalized()
		target = (target - vel * 0.03).normalized()
		var cur: Vector3 = target
		if _dirs[c] != null:
			cur = (_dirs[c] as Vector3).slerp(target, minf(1.0, dt * 14.0)).normalized()
		_dirs[c] = cur
		var pts := [anchor]
		var p := anchor
		for i in SEGS:
			var t := float(i) / SEGS
			var d := cur.lerp((down + radial * 0.25).normalized(), t * 0.5).normalized()
			p += d * seg
			pts.append(p)
		grid.append(pts)
	_draw(grid)

func _draw(grid: Array) -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in COLS:
		var a: Array = grid[c]
		var b2: Array = grid[(c + 1) % COLS]
		for i in SEGS:
			var t1 := float(i + 1) / SEGS
			var c0 := col.darkened(float(i) / SEGS * 0.12)
			var c1 := trim if i == SEGS - 1 else col.darkened(t1 * 0.12)
			var v0: Vector3 = a[i]
			var v1: Vector3 = b2[i]
			var v2: Vector3 = a[i + 1]
			var v3: Vector3 = b2[i + 1]
			var n := (v1 - v0).cross(v2 - v0).normalized()
			for q in [[v0, c0], [v1, c0], [v2, c1], [v1, c0], [v3, c1], [v2, c1]]:
				_im.surface_set_color(q[1])
				_im.surface_set_normal(n)
				_im.surface_add_vertex(q[0])
	_im.surface_end()
