class_name Showcase
extends Node3D
## 3D backdrop for menu screens: an arena with one or two posed bodies.

var arena: Arena
var cam: Camera3D
var bodies: Array[Body] = []
var styles: Array[String] = []
var _t := 0.0
var spin := false
var focus_x := 0.0      # where the camera looks (shift to put the hero left/right)
var _base_yaw: Array[float] = []
var hold := {}          # body index -> pose dict to hold instead of idling

func _init(theme := "temple") -> void:
	arena = Arena.new(theme, 7)

func _ready() -> void:
	add_child(arena)
	cam = Camera3D.new()
	cam.fov = 38
	add_child(cam)
	_place_cam()

func _place_cam() -> void:
	cam.position = Vector3(focus_x, 1.35, 5.2)
	cam.look_at(Vector3(focus_x, 1.0, 0))

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

func add_body(look: Dictionary, style: String, x: float, yaw := -0.5) -> Body:
	var b := Body.new(look)
	b.position = Vector3(x, 0, 0)
	b.rotation.y = yaw
	add_child(b)
	b.apply_pose(Poses.stance(style))
	bodies.append(b)
	styles.append(style)
	_base_yaw.append(yaw)
	return b

func _process(delta: float) -> void:
	_t += delta
	for i in bodies.size():
		var p: Dictionary = hold[i] if hold.has(i) else Poses.idle_breathe(styles[i], _t + i)
		bodies[i].blend_to(p, minf(1.0, delta * 8.0))
		if spin:
			bodies[i].rotation.y = _base_yaw[i] + sin(_t * 0.5) * 0.5

## Strike a pose briefly (e.g. on sect select).
func flourish(i: int, key: String) -> void:
	if i >= bodies.size():
		return
	var b := bodies[i]
	var tw := create_tween()
	var st := styles[i]
	var p := Poses.victory(st) if key == "victory" else Poses.key(key, st)
	tw.tween_method(func(k: float): b.blend_to(p, k), 0.0, 1.0, 0.25)
	tw.tween_interval(0.35)
