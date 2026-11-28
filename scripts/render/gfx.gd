class_name Gfx
## Graphics quality: 0 Thấp, 1 Thường, 2 Cao, 3 Siêu nhẹ (Game.settings["gfx"]).
## Siêu nhẹ runs as level 0 plus ultra(): every level() check that
## means Thấp still holds, and the extra cuts ask ultra() themselves.
## Thường is the look the game shipped with. Glow/adjustment stay desktop-only
## at every level (driver leak on Mali, see Arena._environment); Cao fakes the
## bloom with additive halo sprites instead.

const NAMES := ["Thấp", "Thường", "Cao"]
const HINTS := [
	"Nhẹ máy, tiết kiệm pin: 30 FPS, độ phân giải thấp, ánh sáng đơn giản, bớt cây cối, không bóng đổ.",
	"Cân bằng: 60 FPS, khử răng cưa 2x.",
	"Đẹp nhất: FPS theo màn hình, khử răng cưa 4x, bóng đổ nét, thêm hạt, hào quang và vệt chém dài.",
]
const ULTRA_NAME := "Siêu nhẹ"
const ULTRA_HINT := "Cho máy yếu nhất: 30 FPS, độ phân giải rất thấp, nhân vật giản lược, đấu trường chỉ còn nền và tranh phông, ít hiệu ứng."
## Settings buttons in screen order: settings["gfx"] value, name.
const CHOICES := [[3, ULTRA_NAME], [0, "Thấp"], [1, "Thường"], [2, "Cao"]]

## Chosen level, -1 = auto. Game copies settings["gfx"] here on load (kept
## off the Game autoload so tool scripts can use Gfx too).
static var _lv := -1
## Siêu nhẹ: 1 chosen, 0 not (another level chosen), -1 auto (auto_ultra).
static var _ultra := -1

static func set_level(v) -> void:
	var n := -1 if v == null else clampi(int(v), -1, 3)
	_lv = 0 if n == 3 else n
	_ultra = 1 if n == 3 else (-1 if n < 0 else 0)

## Siêu nhẹ on top of Thấp: no scenery props, one-piece floor, flat sky, no
## fog or lamp lights, half-resolution 3D, coarsest LODs, fewer particles.
static func ultra() -> bool:
	if level() != 0:
		return false
	return auto_ultra() if _ultra < 0 else _ultra == 1

## Auto: PowerVR phones. The 1.5.0 funnel had none of them at 27 FPS or better
## on Thấp (13 first fights, 8 under 15 FPS).
static func auto_ultra() -> bool:
	return OS.has_feature("mobile") and gpu_family() == "powervr"

## The settings value of what is in effect (3 = Siêu nhẹ): funnel tags, buttons.
static func choice() -> int:
	return 3 if ultra() else level()

static func choice_hint() -> String:
	return ULTRA_HINT if ultra() else HINTS[level()]

static func level() -> int:
	return auto_level() if _lv < 0 else _lv

## Thấp: everything cut for weak GPUs (Adreno 5xx / Mali-T8xx).
static func lite() -> bool:
	return level() == 0

static func high() -> bool:
	return level() >= 2

## First-run default: desktop Cao, weak phones Thấp, everything else Thường.
## Weak = little RAM or a weak GPU (1.3.2: Play reviews from PowerVR / low
## Adreno phones that lagged or lost the 3D on Thường).
static func auto_level() -> int:
	if not OS.has_feature("mobile"):
		return 2
	var ram := int(OS.get_memory_info().get("physical", 0))
	if ram > 0 and ram < 3_500_000_000:
		return 0
	if weak_gpu():
		return 0
	return 1

## GPU name as the driver reports it, e.g. "PowerVR Rogue GE8320", "Adreno (TM) 618".
static func gpu_name() -> String:
	return RenderingServer.get_video_adapter_name()

## "powervr" / "mali" / "adreno" / "other": for the funnel.
static func gpu_family(name := "") -> String:
	var g := (name if name != "" else gpu_name()).to_lower()
	if "powervr" in g or g.begins_with("img") or "imagination" in g:
		return "powervr"
	for f in ["mali", "adreno"]:
		if f in g:
			return f
	return "other"

static func weak_gpu() -> bool:
	return weak_gpu_name(gpu_name())

## Entry-level mobile GPUs: every PowerVR (GE8xxx, IMG on Unisoc), Mali-4xx /
## T-series / G31 / G51 / G52, Adreno 3xx–5xx and 610–619. Test: tools/gpu_check.gd
## 1.5.0: also Mali-G57 / G71 / G72 and two-core G6xx (G615 MC2…): the funnel
## had 21 of 34 Mali phones on Thường under 27 FPS in their first fight, most
## of them Mali-G57 MC2 (Helio G99, Dimensity 6100).
static func weak_gpu_name(name: String) -> bool:
	var g := name.to_lower()
	if g == "":
		return false
	if gpu_family(g) == "powervr":
		return true
	if RegEx.create_from_string("mali-(4\\d\\d|t\\d+|g31|g51|g52|g57|g71|g72)\\b").search(g) != null:
		return true
	if RegEx.create_from_string("mali-g6\\d+\\s*m[cp][12]\\b").search(g) != null:
		return true
	var a := RegEx.create_from_string("adreno[^0-9]*(\\d{3})").search(g)
	if a != null:
		var n := int(a.get_string(1))
		return n < 600 or (n >= 610 and n <= 619)
	return false

## Particle-count multiplier for Fx.
static func particles() -> float:
	return 0.25 if ultra() else [0.5, 1.0, 1.8][level()]

## Weapon trail length in frames.
static func trail_len() -> int:
	return 4 if ultra() else [6, 9, 16][level()]

## True while a FightScene is the current screen (Game.goto sets it).
static var _in_fight := false

## Menus on phones run at 30 FPS (Cao: 60): the hub and the other menus draw a
## full 3D arena with skinned fighters every frame, and a phone that heats up
## in the menus throttles in the next fight. Fights keep the level's cap.
static func max_fps() -> int:
	var lv := level()
	if not _in_fight and OS.has_feature("mobile"):
		return 60 if lv >= 2 else 30
	return [30, 60, 0][lv]

static func set_in_fight(on: bool) -> void:
	if on == _in_fight:
		return
	_in_fight = on
	Engine.max_fps = max_fps()

## Frame rate a fight aims for (Cao follows the screen, counted as at most 60).
static func fight_fps() -> float:
	var lv := level()
	if lv == 0:
		return 30.0
	if lv == 1:
		return 60.0
	var hz := DisplayServer.screen_get_refresh_rate()
	return 60.0 if hz <= 0.0 else clampf(hz, 30.0, 60.0)

## The level's 3D render scale; Perf only ever goes below it.
static func base_scale() -> float:
	if ultra():
		return 0.5
	return 0.75 if level() == 0 else 1.0

## Lowest scale Perf may go to.
static func min_scale() -> float:
	return 0.4 if ultra() else 0.5

## Dynamic 3D render scale chosen by Perf (-1 = the level's base), and the
## level it was learned on: settings["gfx_scale"] = {"lv", "s"}.
static var _dyn := -1.0
static var _dyn_lv := -1

static func render_scale() -> float:
	if _dyn < 0.0 or _dyn_lv != choice():
		return base_scale()
	return minf(_dyn, base_scale())

## Sets the dynamic scale now (Perf). Saved by save_scale() after the fight.
static func set_render_scale(s: float) -> void:
	_dyn = s
	_dyn_lv = choice()
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.scaling_3d_scale = render_scale()

## Restores the scale learned in an earlier session (Game start-up).
static func load_scale(d) -> void:
	if d is Dictionary:
		_dyn = float(d.get("s", -1.0))
		_dyn_lv = int(d.get("lv", -1))

static func save_scale(settings: Dictionary) -> void:
	if _dyn < 0.0:
		settings.erase("gfx_scale")
	else:
		settings["gfx_scale"] = {"lv": _dyn_lv, "s": snappedf(_dyn, 0.01)}

## The player picked a level: start again from its own base scale.
static func reset_scale(settings: Dictionary) -> void:
	_dyn = -1.0
	_dyn_lv = -1
	settings.erase("gfx_scale")

## Applies the window-wide settings. Call at start-up and after a change.
static func apply(tree: SceneTree) -> void:
	var lv := level()
	var vp := tree.root
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][lv]
	# weak phones are fill-rate bound (the menu lagged too): fewer 3D pixels;
	# Perf may lower it further while a fight runs slow
	vp.scaling_3d_scale = render_scale()
	# Meshy models carry auto LODs: Thấp switches to the coarse ones much earlier
	# (fighters and scenery are 20–50k triangles each; Adreno 5xx chokes on them)
	# Siêu nhẹ: about 25k instead of 40k triangles for both fighters (desktop count)
	vp.mesh_lod_threshold = (200.0 if ultra() else 6.0) if lv == 0 else 1.0
	Engine.max_fps = max_fps()
	RenderingServer.directional_shadow_atlas_set_size([1024, 2048, 4096][lv], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(
		[RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][lv])

## Real (shadow-mapped) sun shadows. The shadow pass draws every fighter and
## prop again, which alone doubled the triangle count; Thấp uses blob shadows.
static func shadows() -> bool:
	return level() > 0

## Thấp: at most this many copies of a scenery model per arena (-1 = any).
## The snow arena alone placed 26 Meshy pines (~1.1M triangles a frame).
static func prop_cap(name: String) -> int:
	if level() > 0:
		return -1
	if ultra():
		return 0
	return {"pine": 4, "tree": 4, "rock": 3}.get(name, -1)

## Thấp: light per vertex instead of per pixel. The fragment shader then only
## samples the texture, which is most of the cost on a weak GPU. Called for
## every GeometryInstance3D that enters the tree (Game._lite_node), deferred
## so the builders have set their materials.
static func lite_geometry(g: GeometryInstance3D) -> void:
	if not is_instance_valid(g) or not lite() or Diag.on("no_vlit"):
		return
	_vertex_lit(g.material_override)
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			return
		for s in mi.mesh.get_surface_count():
			_vertex_lit(mi.get_active_material(s))

static func _vertex_lit(m: Material) -> void:
	if m is BaseMaterial3D:
		var bm := m as BaseMaterial3D
		if bm.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL:
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			if bm.albedo_texture == null and bm.specular_mode != BaseMaterial3D.SPECULAR_DISABLED:
				# big flat arena shapes lose the sun sheen per vertex: brighten
				var c := bm.albedo_color
				bm.albedo_color = Color(minf(1.0, c.r * 1.3), minf(1.0, c.g * 1.3), minf(1.0, c.b * 1.3), c.a)
	if m != null and m.next_pass != null:
		_vertex_lit(m.next_pass)

## Per-arena sun shadow tweak.
static func sun(light: DirectionalLight3D) -> void:
	var lv := level()
	light.shadow_enabled = light.shadow_enabled and shadows()
	light.shadow_blur = [1.0, 2.2, 1.6][lv]
	light.directional_shadow_max_distance = [20.0, 30.0, 30.0][lv]
