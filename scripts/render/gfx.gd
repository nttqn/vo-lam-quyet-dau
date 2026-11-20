class_name Gfx
## Graphics quality: 0 Thấp, 1 Thường, 2 Cao (Game.settings["gfx"]).
## Thường is the look the game shipped with. Glow/adjustment stay desktop-only
## at every level (driver leak on Mali, see Arena._environment); Cao fakes the
## bloom with additive halo sprites instead.

const NAMES := ["Thấp", "Thường", "Cao"]
const HINTS := [
	"Nhẹ máy, tiết kiệm pin: 30 FPS, ít hạt, bớt cây cối, không bóng đổ.",
	"Cân bằng: 60 FPS, khử răng cưa 2x.",
	"Đẹp nhất: FPS theo màn hình, khử răng cưa 4x, bóng đổ nét, thêm hạt, hào quang và vệt chém dài.",
]

## Chosen level, -1 = auto. Game copies settings["gfx"] here on load (kept
## off the Game autoload so tool scripts can use Gfx too).
static var _lv := -1

static func set_level(v) -> void:
	_lv = -1 if v == null else clampi(int(v), -1, 2)

static func level() -> int:
	return auto_level() if _lv < 0 else _lv

static func high() -> bool:
	return level() >= 2

## First-run default: desktop Cao, weak phones Thấp, everything else Thường.
static func auto_level() -> int:
	if not OS.has_feature("mobile"):
		return 2
	var ram := int(OS.get_memory_info().get("physical", 0))
	if ram > 0 and ram < 3_500_000_000:
		return 0
	return 1

## Particle-count multiplier for Fx.
static func particles() -> float:
	return [0.5, 1.0, 1.8][level()]

## Weapon trail length in frames.
static func trail_len() -> int:
	return [6, 9, 16][level()]

## Applies the window-wide settings. Call at start-up and after a change.
static func apply(tree: SceneTree) -> void:
	var lv := level()
	var vp := tree.root
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][lv]
	vp.scaling_3d_scale = 0.8 if lv == 0 else 1.0
	# Meshy models carry auto LODs: Thấp switches to the coarse ones much earlier
	# (fighters and scenery are 20–50k triangles each; Adreno 5xx chokes on them)
	vp.mesh_lod_threshold = 6.0 if lv == 0 else 1.0
	Engine.max_fps = [30, 60, 0][lv]
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
	return {"pine": 4, "tree": 4, "rock": 3}.get(name, -1)

## Per-arena sun shadow tweak.
static func sun(light: DirectionalLight3D) -> void:
	var lv := level()
	light.shadow_enabled = light.shadow_enabled and shadows()
	light.shadow_blur = [1.0, 2.2, 1.6][lv]
	light.directional_shadow_max_distance = [20.0, 30.0, 30.0][lv]
