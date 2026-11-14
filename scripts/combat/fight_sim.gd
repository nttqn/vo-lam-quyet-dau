class_name FightSim
extends RefCounted
## Two fighters, projectiles, rounds. Deterministic given seed + inputs.

enum { INTRO, FIGHT, ROUND_END, MATCH_END }

const WALL := 7.0
const ROUND_FRAMES := 60 * 60
const INTRO_FRAMES := 100
const END_FRAMES := 150

var f: Array[Fighter] = []
var projs: Array = []
var events: Array = []
var rng := RandomNumberGenerator.new()
var phase := INTRO
var pf := 0                 # frames in phase
var round_no := 1
var round_frames := ROUND_FRAMES   # tower rules can shorten rounds
var timer := ROUND_FRAMES
var wins := [0, 0]
var rounds_to_win := 2
var freeze := 0
var winner := -1            # match winner
var round_winner := -1
var frame := 0
var _pid := 0

func _init(a: Fighter, b: Fighter, seed_ := 0) -> void:
	f = [a, b]
	a.idx = 0
	b.idx = 1
	rng.seed = seed_ if seed_ != 0 else randi()
	_reset_positions()

func emit(e: Dictionary) -> void:
	events.append(e)

func _reset_positions() -> void:
	f[0].reset_round(-1.8, 1)
	f[1].reset_round(1.8, -1)
	projs.clear()
	timer = round_frames

## Advance one tick with both inputs.
func tick(in0: Dictionary, in1: Dictionary) -> void:
	frame += 1
	pf += 1
	match phase:
		INTRO:
			if pf == 1:
				emit({"t": "round", "n": round_no})
			if pf == INTRO_FRAMES - 30:
				emit({"t": "fight"})
			_physics({}, {})
			if pf >= INTRO_FRAMES:
				phase = FIGHT
				pf = 0
		FIGHT:
			if freeze > 0:
				freeze -= 1
				return
			timer -= 1
			_physics(in0, in1)
			_check_round_end()
		ROUND_END:
			_physics({}, {})
			if pf >= END_FRAMES:
				if wins[0] >= rounds_to_win or wins[1] >= rounds_to_win:
					phase = MATCH_END
					pf = 0
					winner = 0 if wins[0] > wins[1] else 1
					emit({"t": "match_end", "winner": winner})
				else:
					round_no += 1
					_reset_positions()
					phase = INTRO
					pf = 0
		MATCH_END:
			_physics({}, {})

func _physics(in0: Dictionary, in1: Dictionary) -> void:
	var a := f[0]
	var b := f[1]
	if phase == FIGHT:
		a.think(in0, b, self)
		b.think(in1, a, self)
	else:
		a.think({}, b, self)
		b.think({}, a, self)
	a.step(b, self)
	b.step(a, self)
	_separate(a, b)
	for ff in f:
		if ff.x < -WALL:
			ff.x = -WALL
			if ff.state == Fighter.AIRHIT and ff.vx < -4.0:
				ff.vx = -ff.vx * 0.3
				emit({"t": "wall", "i": ff.idx, "x": ff.x})
			elif ff.vx < 0:
				ff.vx = 0.0
		elif ff.x > WALL:
			ff.x = WALL
			if ff.state == Fighter.AIRHIT and ff.vx > 4.0:
				ff.vx = -ff.vx * 0.3
				emit({"t": "wall", "i": ff.idx, "x": ff.x})
			elif ff.vx > 0:
				ff.vx = 0.0
	if phase == FIGHT:
		_hits(a, b)
		_hits(b, a)
		_step_projs()

func _separate(a: Fighter, b: Fighter) -> void:
	if a.state in [Fighter.LYING, Fighter.KO] or b.state in [Fighter.LYING, Fighter.KO]:
		return
	if a.y > 0.9 or b.y > 0.9:
		return
	var d := b.x - a.x
	var min_d := Fighter.RADIUS * 2.0
	if absf(d) < min_d:
		var push := (min_d - absf(d)) * 0.5
		var s := 1.0 if d >= 0 else -1.0
		if absf(d) < 0.001:
			s = 1.0 if a.facing > 0 else -1.0
		a.x -= s * push
		b.x += s * push
		# keep the pair inside the walls
		if a.x < -WALL: b.x += -WALL - a.x; a.x = -WALL
		if b.x > WALL: a.x -= b.x - WALL; b.x = WALL
		if b.x < -WALL: a.x += -WALL - b.x; b.x = -WALL
		if a.x > WALL: b.x -= a.x - WALL; a.x = WALL

# ------------------------------------------------------------- hitting
func _can_be_hit(d: Fighter) -> bool:
	return d.inv <= 0 and not d.dead and d.state not in [Fighter.LYING, Fighter.GETUP, Fighter.KO]

func _hits(a: Fighter, d: Fighter) -> void:
	if a.state != Fighter.ATTACK or a.move.is_empty():
		return
	var m := a.move
	var kind: String = m.get("kind", "strike")
	if kind in ["proj", "rain", "buff", "heal"]:
		return
	if kind == "counter":
		return
	if not a.in_active():
		return
	var hits: int = m.get("hits", 1)
	if a.hits_done >= hits:
		return
	# multi-hit spacing inside the active window
	var interval := maxi(1, int(float(m.act) / hits))
	if a.sf - m.st < a.hits_done * interval:
		return
	if not _can_be_hit(d):
		if d.state == Fighter.DODGE and d.inv > 0 and _in_reach(a, d, m):
			insight(a, d, m, 2)     # read the technique while slipping past it
		return
	if not _in_reach(a, d, m):
		return
	resolve(a, d, m, a.hits_done == hits - 1)
	a.hits_done += 1

func _in_reach(a: Fighter, d: Fighter, m: Dictionary) -> bool:
	var front := (d.x - a.x) * a.facing
	if front < -0.25:
		return false
	if front - Fighter.RADIUS * 2.0 > m.reach:
		return false
	var h: String = m.h
	var d_air := d.y > 0.25
	if kind_of(m) == "throw":
		return not d_air and d.state not in [Fighter.HITSTUN, Fighter.AIRHIT] and d.grounded()
	if h == "low" and d_air:
		return false
	if h == "high" and d.crouching() and not d_air:
		return false
	# attacker in the air hitting a grounded crouching target is fine
	if m.get("air", false) and a.y - d.y > 1.6:
		return false
	return true

static func kind_of(m: Dictionary) -> String:
	return m.get("kind", "strike")

## Ngộ chiêu: defender d blocked / dodged / countered a foreign sect's skill.
## Once per move instance; ultimates can't be learned.
func insight(a: Fighter, d: Fighter, m: Dictionary, pts: int) -> void:
	if a.insight_sent or not m.get("skill", false) or m.get("ult", false) or not m.has("slot"):
		return
	var origin: String = m.get("from", a.sect.id)
	if origin == d.sect.id:
		return
	a.insight_sent = true
	emit({"t": "insight", "i": d.idx, "sect": origin, "slot": int(m.slot), "pts": pts, "name": m.get("name", "")})

func _blocked(d: Fighter, m: Dictionary) -> bool:
	if m.get("unblockable", false):
		return false
	if not d.is_blocking():
		return false
	var h: String = m.h
	if m.get("air", false):
		h = "over"
	var crouch := d.hold_down
	match h:
		"low":
			return crouch
		"over":
			return not crouch
	return true

## Apply attack m from a to d. last: final hit of a multi-hit move.
func resolve(a: Fighter, d: Fighter, m: Dictionary, last := true) -> void:
	a.connected = true
	# counter stance
	if d.state == Fighter.ATTACK and kind_of(d.move) == "counter" and d.in_active() and kind_of(m) != "throw":
		d.trigger_counter(self)
		var cm := d.move.duplicate()
		cm["kind"] = "strike"
		cm["launch"] = 6.0
		cm["unblockable"] = true
		emit({"t": "counter", "i": d.idx, "x": d.x})
		insight(a, d, m, 2)
		freeze = 10
		resolve(d, a, cm, true)
		return
	if _blocked(d, m):
		d.set_state(Fighter.BLOCKSTUN)
		d.stun = m.bs
		d.vx = a.facing * absf(m.push) * 0.6
		var chip := 0.0
		if a.sect.get("passive", "") == "am_khi" and m.get("skill", false) and kind_of(m) in ["proj", "rain"]:
			chip = _damage(a, d, m, false) * 0.3
		elif m.get("skill", false):
			chip = _damage(a, d, m, false) * 0.12
		if chip > 0.0:
			d.hp = maxf(1.0, d.hp - chip)
		if d.sect.get("passive", "") == "cuong_nhu":
			if d.ripost <= 0:
				emit({"t": "cuongnhu", "i": d.idx, "on": true})
			d.ripost = 90
			d.en = minf(Fighter.EN_MAX, d.en + 1.0 * d.en_mult())
		d.en = minf(Fighter.EN_MAX, d.en + 2.0 * d.en_mult())
		a.en = minf(Fighter.EN_MAX, a.en + 1.5 * a.en_mult())
		_wall_push(a, d, m)
		insight(a, d, m, 1)
		freeze = 3
		emit({"t": "block", "i": d.idx, "x": (a.x + d.x) * 0.5, "y": 1.2, "fx": m.get("fx", "hit")})
		return
	var crit: bool = rng.randf() < float(a.st.get("crit", 0.05))
	var dmg := _damage(a, d, m, crit)
	if a.ripost > 0:
		a.ripost = 0
		a.en = minf(Fighter.EN_MAX, a.en + 4.0 * a.en_mult())
		emit({"t": "cuongnhu", "i": a.idx, "on": false})
	var mm := m
	if not last and m.get("hits", 1) > 1:
		# intermediate hits of a multi-hit only stagger
		mm = m.duplicate()
		mm["launch"] = 0.0 if d.y < 0.05 else 2.5
		mm["kd"] = false
		mm["push"] = 0.8
		mm["hs"] = 26
	d.take_hit(a, mm, dmg, self, crit)
	a.stats_dealt += dmg
	a.en = minf(Fighter.EN_MAX, a.en + 5.0 * a.st.get("en_gain", 1.0) * a.en_mult())
	a._combo_run += 1
	a.max_combo = maxi(a.max_combo, d.combo_taken)
	_wall_push(a, d, m)
	var heavy: bool = m.dmg >= 1.5 or m.get("skill", false)
	freeze = 7 if heavy else 4
	if d.dead:
		freeze = 18
	emit({"t": "hit", "i": d.idx, "by": a.idx, "x": d.x - a.facing * 0.1, "y": clampf(d.y + (0.5 if m.h == "low" else 1.25), 0.3, 3.0),
		"dmg": dmg, "crit": crit, "heavy": heavy, "fx": m.get("fx", "hit"), "move": m.get("name", "?"), "combo": d.combo_taken, "elem": a.sect.get("elem", Color.WHITE), "skill": m.get("skill", false)})

func _wall_push(a: Fighter, d: Fighter, m: Dictionary) -> void:
	if absf(d.x) >= WALL - 0.05 and not m.get("air", false):
		a.vx = -a.facing * absf(m.push) * 0.7

func _damage(a: Fighter, d: Fighter, m: Dictionary, crit: bool) -> float:
	var power: float = a.st.qi if m.get("skill", false) else a.st.atk
	power *= a.buff_mult("atk")
	if a.ripost > 0:
		power *= 1.35
	if a.seal[0] > 0:
		power *= 0.75 if not m.get("skill", false) else 0.88
	var defv: float = d.st.def * d.buff_mult("def")
	var dmg: float = m.dmg * power * 100.0 / (100.0 + defv)
	dmg *= rng.randf_range(0.93, 1.07)
	# combo scaling
	dmg *= maxf(0.45, 1.0 - 0.08 * maxi(0, d.combo_taken - 1))
	if crit:
		dmg *= 1.6
	return maxf(1.0, dmg)

# ------------------------------------------------------------- projectiles
func spawn_proj(a: Fighter, d: Fighter, m: Dictionary, n: int) -> void:
	var pj: Dictionary = m.proj
	var p := {
		"id": _pid, "owner": a.idx, "m": m, "life": 150,
		"x": a.x + a.facing * 0.5, "y": float(pj.get("y", 1.1)) + a.y,
		"vx": a.facing * float(pj.get("speed", 12.0)), "vy": float(pj.get("vy", 0.0)),
		"grav": float(pj.get("grav", 0.0)), "vis": pj.get("vis", "knife"), "dir": a.facing,
	}
	_pid += 1
	if pj.has("spread"):
		var s: float = pj.spread
		p.vy = (float(n) / float(maxi(1, int(pj.get("n", 1)) - 1)) - 0.5) * 2.0 * s * absf(p.vx) * 0.5
	if m.get("kind", "") == "rain":
		p.x = d.x + d.vx * 0.45 + rng.randf_range(-0.5, 0.5)
		p.y = 7.0 + n * 0.3
		p.vx = 0.0
		p.vy = -14.0
	projs.append(p)
	emit({"t": "proj", "p": p})

func _step_projs() -> void:
	for i in range(projs.size() - 1, -1, -1):
		var p: Dictionary = projs[i]
		p.vy -= p.grav * Fighter.DT
		p.x += p.vx * Fighter.DT
		p.y += p.vy * Fighter.DT
		p.life -= 1
		var dead: bool = p.life <= 0 or absf(p.x) > WALL + 2.0 or p.y < -0.1
		var d := f[1 - int(p.owner)]
		var a := f[int(p.owner)]
		if not dead and d.state == Fighter.DODGE and d.inv > 0 and absf(p.x - d.x) < 0.42:
			insight(a, d, p.m, 2)
		if not dead and _can_be_hit(d):
			var top := d.y + (1.05 if d.crouching() else 1.75)
			if absf(p.x - d.x) < 0.42 and p.y >= d.y - 0.05 and p.y <= top:
				var m: Dictionary = p.m
				resolve(a, d, m, true)
				dead = true
		# projectile clash
		if not dead:
			for q in projs:
				if q.owner != p.owner and absf(q.x - p.x) < 0.4 and absf(q.y - p.y) < 0.6:
					q.life = 0
					dead = true
					emit({"t": "clash", "x": p.x, "y": p.y})
					break
		if dead:
			if p.vis == "bomb" or (p.y <= 0.0 and p.grav > 0.0):
				emit({"t": "boom", "x": p.x, "y": maxf(0.2, p.y)})
			emit({"t": "proj_end", "id": p.id})
			projs.remove_at(i)

# ------------------------------------------------------------- rounds
func _check_round_end() -> void:
	var a := f[0]
	var b := f[1]
	var rw := -1
	if a.dead and b.dead:
		rw = 0 if a.hp >= b.hp else 1
	elif b.dead:
		rw = 0
	elif a.dead:
		rw = 1
	elif timer <= 0:
		var pa: float = a.hp / a.st.hp_max
		var pb: float = b.hp / b.st.hp_max
		rw = 0 if pa >= pb else 1
		emit({"t": "timeup"})
	if rw >= 0:
		round_winner = rw
		wins[rw] += 1
		phase = ROUND_END
		pf = 0
		var w := f[rw]
		emit({"t": "ko", "winner": rw, "perfect": w.hp >= w.st.hp_max - 0.5, "timeup": timer <= 0,
			"final": wins[rw] >= rounds_to_win, "move": f[1 - rw].last_hit})
		if w.state not in [Fighter.AIRHIT, Fighter.LYING]:
			w.set_state(Fighter.WIN)
