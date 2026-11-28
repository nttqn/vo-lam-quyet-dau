extends SceneTree
## Perf (in-fight render-scale guard) on simulated frame rates:
## godot --headless --path . -s tools/perf_check.gd
var bad := 0

func _check(what: String, ok: bool) -> void:
	if not ok:
		bad += 1
	print(("ok   " if ok else "FAIL ") + what + "  [scale %.2f]" % Gfx.render_scale())

## Feeds n whole 2 s windows at a steady fps.
func _feed(fps: float, n: int) -> void:
	for w in n:
		Perf._t = 0.0
		Perf._n = 0
		for i in int(fps * Perf.WIN) + 1:
			Perf.tick(1.0 / fps)

func _init() -> void:
	Perf.test = true
	Gfx.set_level(1)   # Thường: 60 FPS target
	Gfx.reset_scale({})
	Perf.begin_fight()
	_feed(60, 5)
	_check("smooth Thường keeps 1.0", is_equal_approx(Gfx.render_scale(), 1.0))
	_feed(30, 1)
	_check("one slow window -> 0.85", is_equal_approx(Gfx.render_scale(), 0.85))
	_feed(30, 3)
	_check("three more -> floor 0.5", is_equal_approx(Gfx.render_scale(), 0.5))
	_check("not struggling yet", not Perf.struggling)
	_feed(30, 2)
	_check("2 slow windows at floor -> struggling", Perf.struggling)
	_check("lowered flag", Perf.lowered)
	_check("ran_well false", not Perf.ran_well())
	Perf.begin_fight()
	_feed(60, 3)
	_check("3 smooth windows -> climbs to 0.6", is_equal_approx(Gfx.render_scale(), 0.6))
	_feed(30, 1)
	_check("slow right after a climb -> 0.45 clamps to 0.5", is_equal_approx(Gfx.render_scale(), 0.5))
	_feed(60, 6)
	_check("locked after see-saw: stays 0.5", is_equal_approx(Gfx.render_scale(), 0.5))
	_check("ran_well true at 60", Perf.ran_well())
	var st := {}
	Gfx.save_scale(st)
	_check("saved per level", st.get("gfx_scale", {}).get("lv", -9) == 1 and is_equal_approx(float(st.gfx_scale.s), 0.5))
	Gfx.set_level(0)
	_check("other level ignores it (Thấp base 0.75)", is_equal_approx(Gfx.render_scale(), 0.75))
	Gfx.set_level(1)
	Gfx.reset_scale(st)
	_check("reset -> base 1.0, key gone", is_equal_approx(Gfx.render_scale(), 1.0) and not st.has("gfx_scale"))
	Gfx.set_level(0)
	Perf.begin_fight()
	_feed(28, 5)
	_check("Thấp at 28 FPS is not slow", is_equal_approx(Gfx.render_scale(), 0.75))
	_feed(20, 1)
	_check("Thấp at 20 FPS -> 0.6", is_equal_approx(Gfx.render_scale(), 0.6))
	# Siêu nhẹ (settings value 3): level 0 + ultra, base 0.5, floor 0.4
	Gfx.set_level(3)
	Gfx.reset_scale({})
	_check("3 -> level 0 + ultra, choice 3", Gfx.level() == 0 and Gfx.ultra() and Gfx.choice() == 3)
	_check("ultra base 0.5", is_equal_approx(Gfx.render_scale(), 0.5))
	Perf.begin_fight()
	_feed(20, 2)
	_check("ultra slow -> floor 0.4", is_equal_approx(Gfx.render_scale(), 0.4))
	_feed(20, 2)
	_check("ultra struggling at 0.4", Perf.struggling)
	Gfx.set_level(0)
	_check("Thấp chosen: not ultra", not Gfx.ultra() and Gfx.choice() == 0)
	_check("Thấp ignores the ultra scale", is_equal_approx(Gfx.render_scale(), 0.75))
	Gfx.set_level(1)
	_check("Thường: not ultra", not Gfx.ultra() and Gfx.choice() == 1)
	Gfx.set_level(-1)
	_check("auto on desktop: Cao, not ultra", Gfx.choice() == 2)
	print("perf_check: %d bad" % bad)
	quit(1 if bad else 0)
