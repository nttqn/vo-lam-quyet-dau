class_name Diag
extends RefCounted
## Diagnostic switches read once from user://diag.json (pushed with adb on a
## debuggable build), used to bisect device-only problems without rebuilding:
##   adb shell run-as <pkg> sh -c 'echo {\"no_glow\":true} > files/diag.json'
## Keys: no_model (Quaternius instead of sect models), hide_bodies, freeze_bodies,
## no_retarget, no_outline, no_glow, no_fog, no_shadow, no_sky, no_ui, no_arena, empty, memlog, no_lights, no_noise, no_ambient_sky, no_props, no_floor.

static var _d = null

static func on(key: String) -> bool:
	if _d == null:
		_d = {}
		if FileAccess.file_exists("user://diag.json"):
			var p = JSON.parse_string(FileAccess.get_file_as_string("user://diag.json"))
			if p is Dictionary:
				_d = p
				print("DIAG ", _d)
	return bool(_d.get(key, false))

static func value(key: String, default = null):
	on(key)   # make sure the file is loaded
	return _d.get(key, default)
