class_name L
extends RefCounted
## Localization, gettext style: the Vietnamese text itself is the key (same
## model as Kiếm Hiệp).
##
## Every Control already shows its text through Godot's auto-translate, so a
## Label/Button whose text is a known Vietnamese line comes out translated by
## itself: `_Tr` below answers those lookups from our table. Text built in
## code has to translate its pattern first: `L.f("Cấp %d", lv)` or
## `L.t("Đóng")`. Data (sect/move/item names, saves, ids, Firestore fields)
## stays Vietnamese everywhere and is only translated where it is shown.
##
## Tables: res://i18n/<code>.json ({"Vietnamese": "translation"}), filled by
## `node tools/i18n.js sync`. Missing or empty lines fall back to Vietnamese.

const LANGS := ["vi", "zh_Hant", "ko", "en"]
const LABELS := {"vi": "Tiếng Việt", "zh_Hant": "繁體中文", "ko": "한국어", "en": "English"}
## Short mark next to a player from another language (boards, chat).
const TAGS := {"vi": "VN", "zh_Hant": "繁中", "ko": "KR", "en": "EN"}
const _LOCALE := {"vi": "vi", "zh_Hant": "zh_TW", "ko": "ko", "en": "en"}

static var lang := "vi"
static var _table: Dictionary = {}
static var _tr: _Tr
static var _cache: Dictionary = {}

## Translation the TranslationServer asks for every auto-translated Control.
class _Tr extends Translation:
	func _get_message(src_message: StringName, _context: StringName) -> StringName:
		var s := String(src_message)
		var out := L.t(s)
		return StringName(out) if out != s else StringName("")

## The language a phone gets on first launch: Traditional Chinese for
## zh-Hant / TW / HK / MO, Korean on Korean phones, Vietnamese on Vietnamese
## ones and on a UTC+7 clock (many Vietnamese keep the phone in English),
## English for everyone else.
static func default_for(locale: String, utc_minutes: int) -> String:
	var l := locale.replace("-", "_")
	var parts := l.split("_")
	var code := parts[0].to_lower()
	if code == "zh" and ("Hant" in parts or "TW" in parts or "HK" in parts or "MO" in parts):
		return "zh_Hant"
	if code == "ko":
		return "ko"
	if code == "vi" or "VN" in parts or utc_minutes == 420:
		return "vi"
	return "en"

## Called once at start (Game._ready): saved choice, else the phone's. A
## player who already has a hero on this phone stays in Vietnamese unless
## the phone is Chinese / Korean (they all started in Vietnamese).
static func init_from(settings: Dictionary, played: bool) -> void:
	var saved := str(settings.get("lang", ""))
	if saved in LANGS:
		use(saved)
		return
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var l := default_for(OS.get_locale(), bias)
	if played and l == "en":
		l = "vi"
	if played:
		settings["lang"] = l   # kept, so a later English phone does not switch it
	use(l)

static func use(code: String) -> void:
	if not code in LANGS:
		code = "vi"
	var table := {}
	if code != "vi":
		var path := "res://i18n/%s.json" % code
		var f := FileAccess.open(path, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f else null
		if d is Dictionary:
			for k in d:
				var v = d[k]
				if v is String and v != "":
					table[k] = v
		else:
			push_warning("i18n: %s table failed, playing in Vietnamese" % code)
			code = "vi"
	lang = code
	_table = table
	_cache.clear()
	if _tr == null:
		_tr = _Tr.new()
		TranslationServer.add_translation(_tr)
	_tr.locale = _LOCALE[code]
	TranslationServer.set_locale(_LOCALE[code])

## [vi] in the language in use. A name built from parts ("Huyền Thiết Côn")
## with no line of its own is joined from its words when every word is known.
static func t(vi: String) -> String:
	if _table.is_empty() or vi == "":
		return vi
	var s = _table.get(vi)
	if s != null:
		return s
	if lang == "en":
		return vi   # word-by-word names read badly in English ("Hide Sword"): keep the Vietnamese
	if _cache.has(vi):
		return _cache[vi]
	var c := _compose(vi)
	_cache[vi] = c
	return c

## Pattern [fmt] translated, then filled with [args] (one value or an
## Array); String values that are known lines get translated too.
static func f(fmt: String, args = null) -> String:
	var p := t(fmt)
	if args == null:
		return p
	if args is Array:
		var a := []
		for v in args:
			a.append(_arg(v))
		return p % a
	return p % _arg(args)

static func _arg(v):
	if v is String or v is StringName:
		return t(String(v))
	return v

static func cjk() -> bool:
	return lang == "zh_Hant" or lang == "ko"

static func _compose(vi: String) -> String:
	if not " " in vi or vi.length() > 60 or "\n" in vi:
		return vi
	var words := vi.strip_edges().split(" ", false)
	var out := []
	var i := 0
	var num := RegEx.create_from_string("^[\\d+★·×x%.,:()\\-]+$")
	while i < words.size():
		var hit = null
		var n := 0
		for len in range(mini(4, words.size() - i), 0, -1):
			var key := " ".join(words.slice(i, i + len))
			if _table.has(key):
				hit = _table[key]
				n = len
				break
		if hit == null:
			if num.search(words[i]) != null:
				hit = words[i]
				n = 1
			else:
				return vi
		out.append(hit)
		i += n
	return ("" if lang == "zh_Hant" else " ").join(out)

## Game._exit_tree: unregister before the script engine shuts down (a
## script-made Translation left in the TranslationServer crashes on exit).
static func shutdown() -> void:
	if _tr != null:
		TranslationServer.remove_translation(_tr)
		_tr = null
