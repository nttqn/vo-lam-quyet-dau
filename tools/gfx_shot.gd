extends SceneTree
## Same hit effects at a fixed moment, to compare graphics levels.
##   godot --path . --resolution 1280x720 --script res://tools/gfx_shot.gd -- out_prefix level
## Saves <prefix>_a.png (spark peak) and <prefix>_b.png (embers drifting).

var _n := 0
var _out := ""
var _fx: Fx

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	Gfx.set_level(int(args[1]))
	Gfx.apply(self)
	var arena := Arena.new("temple", 1)
	get_root().add_child(arena)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.position = Vector3(0, 1.4, 4.2)
	get_root().add_child(cam)
	cam.look_at(Vector3(0, 1.1, 0))
	cam.current = true
	_fx = Fx.new()
	get_root().add_child(_fx)

func _process(_d: float) -> bool:
	_n += 1
	if _n == 10:
		seed(7)
		_fx.spark(Vector3(-0.6, 1.3, 0.15), Color(1.0, 0.55, 0.2), true, "slash")
		_fx.spark(Vector3(0.7, 1.0, 0.15), Color(0.5, 0.8, 1.0), false, "hit")
		_fx.ground_ring(0.2, Color(0.6, 1.0, 0.7))
		_fx.dust(0.2)
	if _n == 14:
		get_root().get_texture().get_image().save_png(_out + "_a.png")
	if _n == 40:
		get_root().get_texture().get_image().save_png(_out + "_b.png")
		quit()
	return false
