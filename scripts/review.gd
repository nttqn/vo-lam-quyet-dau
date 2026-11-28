class_name Review
extends RefCounted
## Play in-app review (1.5.0, Android only: VLReview in the VLGoogleAuth AAR).
## The Play rating came mostly from players whose phones lagged; players who
## enjoy the game never got asked. Asked after a won fight once the hero has
## 10 wins, is at least a day old and the fight ran smoothly (Perf.ran_well),
## at most twice per phone, 60 days apart. Play decides whether the card
## really shows (it has its own quota), so this never says anything itself.
## Silent no-op on desktop and iOS.

const _PLUGIN := "VLReview"
const WINS := 10
const MAX_ASKS := 2
const GAP_S := 60 * 86400

static var _p: Object = null
static var _looked := false

static func _plugin() -> Object:
	if not _looked:
		_looked = true
		if Engine.has_singleton(_PLUGIN):
			_p = Engine.get_singleton(_PLUGIN)
	return _p

static func due(h: Dictionary) -> bool:
	if _plugin() == null or h.is_empty():
		return false
	if int(h.get("wins", 0)) < WINS or Funnel.days_since(float(h.get("created", 0))) < 1:
		return false
	if not Perf.ran_well():
		return false
	var n := int(Game.settings.get("review_n", 0))
	var last := float(Game.settings.get("review_t", 0.0))
	return n < MAX_ASKS and (n == 0 or Time.get_unix_time_from_system() - last > GAP_S)

static func ask() -> void:
	var p := _plugin()
	if p == null:
		return
	Game.settings["review_n"] = int(Game.settings.get("review_n", 0)) + 1
	Game.settings["review_t"] = Time.get_unix_time_from_system()
	Game.save_settings()
	Funnel.device("f_review_ask%d" % int(Game.settings.review_n))
	p.request()
