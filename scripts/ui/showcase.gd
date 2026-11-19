class_name Showcase
extends Node3D
## 3D backdrop for menu screens: an arena with one or two skinned fighters.

var arena: Arena
var cam: Camera3D
var bodies: Array[Avatar] = []
var styles: Array[String] = []
var _t := 0.0
var spin := false
var focus_x := 0.0
var _base_yaw: Array[float] = []
var hold := {}          # body index -> {"clip": name, "frac": 0..1 or -1 = loop}

func _init(theme := "temple") -> void:
	arena = Arena.new(theme, 7)

func _ready() -> void:
	if not Diag.on("no_arena"):
		add_child(arena)
	cam = Camera3D.new()
	cam.fov = 38
	add_child(cam)
	_place_cam()

## Camera distance / height / look height (a giant needs a wider frame).
var cam_d := 5.2
var cam_y := 1.35
var look_y := 1.0

func _place_cam() -> void:
	cam.position = Vector3(focus_x, cam_y, cam_d)
	cam.look_at(Vector3(focus_x, look_y, 0))

func set_focus(x: float) -> void:
	focus_x = x
	if cam:
		_place_cam()

func clear() -> void:
	for b in bodies:
		b.queue_free()
	bodies.clear()
	styles.clear()
	_base_yaw.clear()
	hold.clear()

## yaw: radians, 0 = facing the camera. Old callers passed small negative
## angles meaning "facing right, turned a bit toward the camera".
func add_body(look: Dictionary, style: String, x: float, yaw := -0.5) -> Avatar:
	var b := Avatar.new(look)
	b.position = Vector3(x, 0, 0)
	var y := yaw
	if absf(yaw) < 1.2:
		y = PI * 0.5 + yaw * 1.4        # facing right, turned toward camera
	else:
		y = -PI * 0.5 + (yaw - PI) * 1.4   # facing left
	b.rotation.y = y
	add_child(b)
	bodies.append(b)
	styles.append(style)
	_base_yaw.append(y)
	return b

func _process(delta: float) -> void:
	_t += delta
	for i in bodies.size():
		var b := bodies[i]
		if not b.is_inside_tree() or b.ap == null:
			continue
		if hold.has(i):
			var h: Dictionary = hold[i]
			var fr: float = h.get("frac", -1.0)
			if fr < 0.0:
				b.pose(h.clip, _t, 0.2)
			else:
				b.pose(h.clip, b.clip_len(h.clip) * fr, 0.2)
		else:
			var ic := AnimMap.idle_clip(styles[i], str(b.look.get("model", "")))
			if ic[0] == "a/Punch_Enter":
				var ph := fposmod(_t * 0.6 + i, 2.0)
				var fr2: float = ic[1] + (ic[2] - ic[1]) * (ph if ph < 1.0 else 2.0 - ph)
				b.pose(ic[0], b.clip_len(ic[0]) * fr2, 0.0)
			else:
				b.pose(ic[0], _t + i, 0.0)
		b.finish(delta)
		if spin or turnable:
			b.rotation.y = _base_yaw[i] + turn + sin(_t * 0.5) * 0.6 * _spin_w

# ------------------------------------------------------------ swipe to turn
## Set by Screen.enable_turn(): the player can swipe to spin the fighters.
var turnable := false
var turn := 0.0          # extra yaw from the player's swipes (radians)
var dragging := false
var _turn_v := 0.0       # fling speed after release (rad/s)
var _idle := 99.0        # seconds since the last swipe
var _spin_w := 1.0       # auto-sway weight, faded out while the player turns

const TURN_PER_PX := 0.012
const TURN_BACK_AFTER := 5.0

func drag_begin() -> void:
	dragging = true
	_turn_v = 0.0
	_idle = 0.0

var _last_vx := 0.0
var _last_move_ms := 0

func drag_by(dx: float, vx: float) -> void:
	turn += dx * TURN_PER_PX
	_last_vx = vx
	_last_move_ms = Time.get_ticks_msec()
	_idle = 0.0

func drag_end() -> void:
	dragging = false
	# fling only if the finger was still moving when it lifted
	var vx := _last_vx if Time.get_ticks_msec() - _last_move_ms < 90 else 0.0
	_turn_v = clampf(vx * TURN_PER_PX * 0.5, -8.0, 8.0)
	_idle = 0.0

func _physics_process(delta: float) -> void:
	if not turnable:
		return
	_idle += delta
	var busy := dragging or _idle < TURN_BACK_AFTER
	_spin_w = move_toward(_spin_w, 0.0 if busy else 1.0, delta * (4.0 if busy else 0.5))
	if dragging:
		return
	if absf(_turn_v) > 0.01:
		turn += _turn_v * delta
		_turn_v *= exp(-2.5 * delta)
		_idle = 0.0
	elif _idle > TURN_BACK_AFTER:
		# drift back to the posed angle the short way round
		turn = wrapf(turn, -PI, PI)
		turn = lerpf(turn, 0.0, 1.0 - exp(-1.5 * delta))
