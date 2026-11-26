class_name GameClock
extends RefCounted
## The game's clock for every daily / weekly reset (1.5.0, ported from Kiếm
## Hiệp's GameClock).
##
## Some players set the phone's date ahead to collect tomorrow's check-in,
## missions, Phó Bản entries, boss tries and Tỉ Võ tickets again and again.
## Once the server's time is known (the Date header of any Google answer,
## Cloud.sync_time) the game counts on from it with the monotonic tick
## counter, which no change to the phone's clock moves; it asks again each
## time the app comes back. Offline it uses the phone's clock but never goes
## below the latest trusted time, and days are held at the end of the local
## day of that trusted time: setting the phone ahead brings no new day until
## the game has been online once that day. A phone that has never been
## online keeps its own clock.

static var _server_base := -1.0     # unix seconds the server said, at _mono_base
static var _mono_base := 0
static var _floor := 0.0            # latest trusted unix time (kept in settings)
static var device_override := -1.0  # tests: pretend the phone says this

static func device() -> float:
	return device_override if device_override >= 0.0 else Time.get_unix_time_from_system()

static func trusted() -> bool:
	return _server_base >= 0.0

## Unix seconds, trusted when possible.
static func now() -> float:
	if trusted():
		return _server_base + (Time.get_ticks_msec() - _mono_base) / 1000.0
	return maxf(device(), _floor)

## The time days and weeks are counted by: now(), but offline never past
## the end of the local day of the latest trusted time.
static func day_now() -> float:
	var n := now()
	if trusted() or _floor <= 0.0:
		return n
	return minf(n, day_end(_floor))

## Offline past the end of the last trusted day: a new day waits for a connection.
static func day_held() -> bool:
	return not trusted() and _floor > 0.0 and now() > day_end(_floor)

static func bias_s() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60

## Last second of the phone's local day holding unix time t.
static func day_end(t: float) -> float:
	var local := t + bias_s()
	return local - fmod(local, 86400.0) + 86400.0 - 1.0 - bias_s()

## Local date "YYYY-MM-DD" of the day clock.
static func today() -> String:
	return Time.get_date_string_from_unix_time(int(day_now()) + bias_s())

## The server said it is t (unix seconds) now.
static func synced(t: float) -> void:
	_server_base = t
	_mono_base = Time.get_ticks_msec()
	_floor = t   # the server is the truth, even below a floor a fast clock pushed up

## How far the phone's clock runs ahead of the trusted one (seconds), 0 if unknown.
static func skew() -> float:
	return device() - now() if trusted() else 0.0

static func get_floor() -> float:
	return maxf(_floor, now() if trusted() else 0.0)

static func set_floor(t: float) -> void:
	_floor = maxf(_floor, t)

## Back to a fresh launch (tests).
static func reset() -> void:
	_server_base = -1.0
	_mono_base = 0
	_floor = 0.0
	device_override = -1.0

const _MONTHS := {"Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12}

## Unix seconds of an HTTP Date header value ("Thu, 26 Nov 2026 10:01:07 GMT"), -1 if unreadable.
static func parse_http_date(v: String) -> float:
	var p := v.strip_edges().split(" ", false)
	if p.size() < 5 or not _MONTHS.has(p[2]):
		return -1.0
	var hms := p[4].split(":")
	if hms.size() != 3:
		return -1.0
	var y := int(p[3])
	if y < 2020:
		return -1.0
	return float(Time.get_unix_time_from_datetime_dict({"year": y, "month": _MONTHS[p[2]], "day": int(p[1]),
		"hour": int(hms[0]), "minute": int(hms[1]), "second": int(hms[2])}))
