class_name Perf
extends RefCounted
## In-fight frame-rate guard (1.5.0). The first-fight funnel had about half of
## the phones under 20 FPS (Mali on Thường, every PowerVR even on Thấp) and
## the Play reviews said "lag". While a duel is live, FightScene feeds every
## frame here; each 2 s window is judged:
##   slow   → the 3D render scale drops one step (floor 0.5),
##   smooth → after 3 such windows in a row it climbs back 0.1 toward the
##            level's base, unless a climb was followed by a slow window
##            this session (then it stays put: no see-saw).
## The scale is saved after the fight (settings "gfx_scale"), so the next one
## starts where this one ended. Slow while already at the floor →
## `struggling`, and the result screen offers Thấp (Thường/Cao only).
## Phones only: desktop runs are tests and screenshots. No Game/Funnel here
## (tools/perf_check.gd runs without autoloads): FightScene saves and reports.

const WIN := 2.0          # seconds of live fight per judged window
const STEP_DOWN := 0.15
const STEP_UP := 0.1
const FLOOR := 0.5

static var _t := 0.0
static var _n := 0
static var _good := 0
static var _floor_bad := 0
static var _since_up := 99
static var _locked := false      # a climb went slow again: no more climbing this session
static var _ft := 0.0            # whole fight: live seconds and frames
static var _fn := 0
static var struggling := false   # this fight: still slow at the floor scale
static var lowered := false      # this fight lowered the scale at least once
static var test := false         # tools/perf_check.gd: run on desktop too

static func on() -> bool:
	return test or (OS.has_feature("mobile") and not Diag.on("no_perf"))

static func begin_fight() -> void:
	_t = 0.0
	_n = 0
	_good = 0
	_floor_bad = 0
	_ft = 0.0
	_fn = 0
	struggling = false
	lowered = false

## Average FPS over the live part of the last fight (0 = too short to tell).
static func fight_avg() -> float:
	return _fn / _ft if _ft > 5.0 else 0.0

## The last fight ran well: average at least 85% of the level's target.
static func ran_well() -> bool:
	var a := fight_avg()
	return a > 0.0 and a >= Gfx.fight_fps() * 0.85 and not struggling

## One live frame (FIGHT phase, not paused, normal speed).
static func tick(delta: float) -> void:
	delta = minf(delta, 0.25)   # one hitch is not a slow phone
	_ft += delta
	_fn += 1
	if not on():
		return
	_t += delta
	_n += 1
	if _t < WIN:
		return
	var fps := _n / _t
	_t = 0.0
	_n = 0
	_since_up += 1
	var target := Gfx.fight_fps()
	var slow := fps < (26.0 if target <= 30.0 else 40.0)
	var smooth := fps >= target * 0.93
	var s := Gfx.render_scale()
	if slow:
		_good = 0
		if _since_up <= 2:
			_locked = true
		if s > FLOOR + 0.01:
			Gfx.set_render_scale(maxf(FLOOR, s - STEP_DOWN))
			lowered = true
		else:
			_floor_bad += 1
			if _floor_bad >= 2:
				struggling = true
	elif smooth:
		_good += 1
		if _good >= 3 and not _locked and s < Gfx.base_scale() - 0.01:
			Gfx.set_render_scale(minf(Gfx.base_scale(), s + STEP_UP))
			_good = 0
			_since_up = 0
	else:
		_good = 0
