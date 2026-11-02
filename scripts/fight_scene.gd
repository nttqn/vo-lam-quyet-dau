class_name FightScene
extends Node3D
## One match: 3D stage + two fighter puppets + HUD + controls.

signal finished(result: Dictionary)

var cfg: Dictionary
var sim: FightSim
var views: Array[FighterView] = []
var ai: FightAI
var ai_p: FightAI           # autoplay for tests / demo
var cam: Camera3D
var fx: Fx
var hud: Hud
var pad: TouchPad
var arena: Arena
var paused := false
var _shake := 0.0
var _cam_x := 0.0
var _cam_d := 6.0
var _zoom_t := 0.0
var _slowmo := 0.0
var _done := false
var _end_t := 0.0
var _pause_layer: CanvasLayer
var _frames := 0
var _shot := ""
var _shot_frames: Array = []
var _quit_after_shot := false
var _ui_layer: CanvasLayer

func _init(p_cfg: Dictionary) -> void:
	cfg = p_cfg

static func make_fighter(side: Dictionary) -> Fighter:
	var f := Fighter.new()
	var s := Sects.get_sect(side.sect)
	f.setup(s, side.stats, side.skills)
	f.name = side.name
	f.title = side.get("title", "")
	return f

func _ready() -> void:
	var fp := make_fighter(cfg.p)
	var fe := make_fighter(cfg.e)
	sim = FightSim.new(fp, fe, cfg.get("seed", 0))
	sim.rounds_to_win = cfg.get("rounds", 2)
	ai = FightAI.new(fe, cfg.e.get("ai", 0.5))
	if cfg.get("autoplay", false) or Game.autoplay:
		ai_p = FightAI.new(fp, 0.8)
	arena = Arena.new(cfg.get("theme", "temple"), cfg.get("seed", 1))
	add_child(arena)
	fx = Fx.new()
	add_child(fx)
	for i in 2:
		var side: Dictionary = cfg.p if i == 0 else cfg.e
		var v := FighterView.new(sim.f[i], side.look)
		add_child(v)
		views.append(v)
		_shadow(v)
	cam = Camera3D.new()
	cam.fov = 42
	cam.near = 0.1
	cam.far = 200
	add_child(cam)
	_cam_x = 0.0
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	_ui_layer.add_child(root)
	root.add_child(UI.vignette(0.5))
	hud = Hud.new()
	hud.sim = sim
	hud.names = [fp.name, fe.name]
	hud.levels = [cfg.p.level, cfg.e.level]
	root.add_child(hud)
	pad = TouchPad.new()
	pad.fighter = fp
	pad.show_buttons = not cfg.get("autoplay", false) or "--pad" in OS.get_cmdline_user_args()
	root.add_child(pad)
	var pb := Button.new()
	pb.text = "II"
	pb.custom_minimum_size = Vector2(64, 56)
	pb.position = Vector2(0, 0)
	pb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pb.offset_left = -32
	pb.offset_right = 32
	pb.offset_top = 92
	pb.offset_bottom = 148
	pb.pressed.connect(toggle_pause)
	root.add_child(pb)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		if a.begins_with("--shotat="):
			for s in a.substr(9).split(","): _shot_frames.append(int(s))
			_quit_after_shot = true
	Game.music("fight")

func _shadow(v: FighterView) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.1, 0.7)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.45))
	g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = gt
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v.set_meta("shadow", mi)
	add_child(mi)

func toggle_pause() -> void:
	if _done:
		return
	paused = not paused
	if paused:
		_show_pause()
	elif _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		toggle_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED and not paused and not _done:
		toggle_pause()

func _show_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 10
	add_child(_pause_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	_pause_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	var p := UI.panel()
	c.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var h := UI.heading("Tạm Dừng", 52)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	v.add_child(UI.gold_button("Tiếp tục", toggle_pause, 28, 320))
	v.add_child(UI.button("Hướng dẫn điều khiển", _show_help, 24, 320))
	v.add_child(UI.button("Bỏ cuộc", func(): _forfeit(), 24, 320))

func _show_help() -> void:
	var d := AcceptDialog.new()
	d.title = "Điều khiển"
	d.dialog_text = "Cần điều khiển (trái): đi / lùi; đẩy lên = nhảy; kéo xuống = ngồi.\nGiữ hướng LÙI để đỡ đòn (ngồi + lùi để đỡ đòn thấp).\n\nQuyền / Cước: bấm liên tục để ra combo.\nTiến + Quyền/Cước: đòn lao tới.  Ngồi + Cước: quét chân.\nNé: lùi né (bất tử ngắn).  Tiến + Né: lướt tới.\nTiến + Né khi sát đối thủ: Cầm Nã (quật ngã, phá đỡ).\n\nTuyệt chiêu tiêu hao Nội Lực (thanh xanh).\nĐánh trúng có thể nối thẳng sang tuyệt chiêu."
	d.theme = UI.theme()
	_pause_layer.add_child(d)
	d.popup_centered(Vector2i(820, 420))

func _forfeit() -> void:
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	paused = false
	_done = true
	_finish(false, true)

func _physics_process(_delta: float) -> void:
	if paused or _done and _end_t > 2.5:
		return
	var inp := pad.poll()
	if ai_p:
		inp = ai_p.decide(sim)
	var ein := ai.decide(sim)
	sim.tick(inp, ein)
	if cfg.get("training", false):
		sim.timer = FightSim.ROUND_FRAMES
		for ff in sim.f:
			if ff.hp < ff.st.hp_max * 0.25 and not ff.dead:
				ff.hp = ff.st.hp_max
		sim.f[0].en = minf(Fighter.EN_MAX, sim.f[0].en + 0.25)
	_frames += 1
	if _shot != "" and _shot_frames.has(_frames):
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot.replace(".png", "_%d.png" % _frames))
		print("shot ", _shot)
		if _quit_after_shot and _frames == _shot_frames.max():
			get_tree().quit()
	_events()

func _events() -> void:
	for e in sim.events:
		match e.t:
			"round":
				hud.banner("Hiệp %d" % e.n, "", 1.3)
				fx.clear_projs()
				Game.sfx("gong")
			"fight":
				hud.banner("Đấu!", "", 0.9, Color(1, 0.4, 0.3))
				Game.sfx("start")
			"hit":
				var col: Color = e.elem if e.skill else Color(1, 0.85, 0.5)
				fx.spark(Vector3(e.x, e.y, 0.15), col, e.heavy, e.fx)
				fx.number(Vector3(e.x, e.y + 0.3, 0.2), e.dmg, e.crit)
				views[e.i].body.flash(0.9 if e.heavy else 0.6)
				_shake = maxf(_shake, 0.16 if e.heavy else 0.06)
				if e.combo >= 2:
					hud.combo(e.by, e.combo)
				Game.sfx("hit_heavy" if e.heavy else ("slash" if e.fx == "slash" else "hit"))
				if e.by == 0:
					Game.vibrate(30 if e.heavy else 15)
			"block":
				fx.spark(Vector3(e.x, e.y, 0.2), Color(0.6, 0.8, 1.0), false, "block")
				Game.sfx("block")
			"armor":
				fx.text(Vector3(sim.f[e.i].x, 2.2, 0.3), "Bá Thể", Color(1, 0.8, 0.3))
				views[e.i].body.flash(0.4)
				Game.sfx("block")
			"counter":
				fx.ring(Vector3(e.x, 1.2, 0.2), Color(0.6, 0.9, 1.0), 1.5)
				fx.text(Vector3(e.x, 2.3, 0.3), "Phản Đòn!", Color(0.6, 0.9, 1.0))
				Game.sfx("counter")
			"skill":
				hud.skill(e.i, e.name)
				var f: Fighter = sim.f[e.i]
				fx.ground_ring(f.x, f.sect.elem)
				Game.sfx("skill")
				if e.ult:
					_zoom_t = 1.0
					hud.banner(e.name, "Tuyệt Kỹ", 1.0, f.sect.elem)
			"swing":
				Game.sfx("swing")
			"buff":
				var f2: Fighter = sim.f[e.i]
				fx.ground_ring(f2.x, f2.sect.elem)
				fx.text(Vector3(f2.x, 2.3, 0.3), "Tăng Lực", f2.sect.elem)
			"heal":
				var f3: Fighter = sim.f[e.i]
				fx.ground_ring(f3.x, Color(0.5, 1.0, 0.6))
				fx.number(Vector3(f3.x, 2.0, 0.3), e.amt, false, Color(0.5, 1.0, 0.5))
				Game.sfx("heal")
			"blink":
				fx.dust(e.from)
				fx.dust(e.to)
				Game.sfx("swing")
			"proj":
				var p: Dictionary = e.p
				var owner: Fighter = sim.f[p.owner]
				fx.add_proj(p, owner.sect.elem)
				Game.sfx("throw")
			"proj_end":
				fx.end_proj(e.id)
			"boom":
				fx.spark(Vector3(e.x, e.y, 0.2), Color(1.0, 0.5, 0.15), true, "fire")
				fx.dust(e.x)
				_shake = 0.2
				Game.sfx("boom")
			"clash":
				fx.spark(Vector3(e.x, e.y, 0.2), Color.WHITE, false, "hit")
			"land":
				fx.dust(e.x)
				_shake = maxf(_shake, 0.05)
				Game.sfx("land")
			"wall":
				fx.dust(e.x)
				_shake = 0.18
				Game.sfx("hit_heavy")
			"ko":
				_slowmo = 1.4
				if e.timeup:
					hud.banner("Hết Giờ", "", 2.0)
				else:
					hud.banner("Hạ Gục!", "Toàn thắng" if e.perfect else "", 2.0, Color(1, 0.3, 0.2))
				Game.sfx("ko")
			"match_end":
				_done = true
				var won: bool = e.winner == 0
				hud.banner("Chiến Thắng" if won else "Thất Bại", "", 3.0, UI.GOLD if won else Color(0.7, 0.7, 0.75))
				Game.sfx("win" if won else "lose")
	sim.events.clear()

func _finish(won: bool, forfeit := false) -> void:
	var fp: Fighter = sim.f[0]
	var res := {
		"won": won, "forfeit": forfeit, "rounds_won": sim.wins[0], "rounds_lost": sim.wins[1],
		"hp_left": fp.hp / fp.st.hp_max, "max_combo": fp.max_combo, "seconds": sim.frame / 60.0,
		"perfect": won and sim.wins[1] == 0,
	}
	Engine.time_scale = 1.0
	finished.emit(res)

func _process(delta: float) -> void:
	if _slowmo > 0:
		_slowmo -= delta / maxf(0.1, Engine.time_scale)
		Engine.time_scale = 0.3 if _slowmo > 0 else 1.0
	if _done and not paused:
		_end_t += delta
		if _end_t > 2.8 and _end_t - delta <= 2.8:
			_finish(sim.winner == 0)
	fx.sync_projs(sim.projs)
	for v in views:
		v.intro_frame = sim.pf if sim.phase == FightSim.INTRO else -1
		var sh: MeshInstance3D = v.get_meta("shadow")
		sh.position = Vector3(v.f.x, 0.06, 0)
		var s := clampf(1.0 - v.f.y * 0.25, 0.4, 1.0)
		sh.scale = Vector3(s, 1, s)
	_camera(delta)

func _camera(delta: float) -> void:
	var a: Fighter = sim.f[0]
	var b: Fighter = sim.f[1]
	var mid := (a.x + b.x) * 0.5
	var sep := absf(a.x - b.x)
	var target_d := clampf(3.6 + sep * 0.75, 5.0, 9.0)
	if _zoom_t > 0:
		_zoom_t -= delta
		target_d = 4.2
	_cam_x = lerpf(_cam_x, mid, minf(1.0, delta * 5.0))
	_cam_x = clampf(_cam_x, -FightSim.WALL + 2.5, FightSim.WALL - 2.5)
	_cam_d = lerpf(_cam_d, target_d, minf(1.0, delta * 3.0))
	var ymax := maxf(a.y, b.y)
	var look := Vector3(_cam_x, 1.05 + ymax * 0.35, 0)
	var pos := Vector3(_cam_x, 1.55 + ymax * 0.3 + _cam_d * 0.05, _cam_d)
	if _shake > 0:
		_shake = maxf(0.0, _shake - delta * 0.6)
		var s := _shake
		pos += Vector3(randf_range(-s, s), randf_range(-s, s), 0)
	cam.position = pos
	cam.look_at(look)
