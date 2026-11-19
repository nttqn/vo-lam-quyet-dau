class_name Analytics
extends RefCounted
## Firebase Analytics (Android only, VLAnalytics in the VLGoogleAuth AAR).
## Firebase starts by itself at launch, so active users, sessions and
## first_open show up in the console (Realtime too) with no call here; these
## add screen names and the game's own events. Silent no-op elsewhere.

const _PLUGIN := "VLAnalytics"
static var _p: Object = null
static var _looked := false

static func _plugin() -> Object:
	if not _looked:
		_looked = true
		if Engine.has_singleton(_PLUGIN):
			_p = Engine.get_singleton(_PLUGIN)
	return _p

## Event names: letters, digits, _; at most 40 chars, starting with a letter.
static func event(name: String, params := {}) -> void:
	var p := _plugin()
	if p:
		p.logEvent(name.substr(0, 40), params)

static func screen(name: String) -> void:
	var p := _plugin()
	if p and name != "":
		p.screen(name)

static func user_property(name: String, value: String) -> void:
	var p := _plugin()
	if p:
		p.setUserProperty(name, value.substr(0, 36))
