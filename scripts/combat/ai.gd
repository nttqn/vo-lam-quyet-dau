class_name FightAI
extends RefCounted
## Opponent brain. Reads the sim with a reaction delay and produces the same
## input dict a human would. `lvl` 0..1 scales reaction, blocking and combos.

var me: Fighter
var lvl := 0.5
var rng := RandomNumberGenerator.new()
var react := 18                 # frames of reaction delay
var block_p := 0.5
var aggro := 0.5
var combo_p := 0.5
var _hist: Array = []           # opponent snapshots for delayed perception
var _plan := ""                 # current intent
var _plan_t := 0
var _hold_mx := 0
var _hold_down := false
var _cool := 0
var _block_t := 0

func _init(p_me: Fighter, p_lvl: float, seed_ := 0) -> void:
	me = p_me
	lvl = clampf(p_lvl, 0.0, 1.0)
	rng.seed = seed_ if seed_ != 0 else randi()
	react = int(lerpf(26.0, 7.0, lvl))
	block_p = lerpf(0.15, 0.85, lvl)
	aggro = lerpf(0.35, 0.7, lvl)
	combo_p = lerpf(0.25, 0.95, lvl)

func _snap(o: Fighter) -> Dictionary:
	return {"x": o.x, "y": o.y, "state": o.state, "sf": o.sf, "move": o.move, "crouch": o.crouching(), "facing": o.facing}

func decide(sim: FightSim) -> Dictionary:
	var o: Fighter = sim.f[1 - me.idx]
	_hist.append(_snap(o))
	if _hist.size() > react + 1:
		_hist.pop_front()
	var seen: Dictionary = _hist[0]
	var inp := {"mx": 0, "up": false, "down": false, "btn": ""}
	if me.dead or sim.phase != FightSim.FIGHT:
		return inp
	var dist := absf(o.x - me.x)
	var toward := me.facing
	var away := -me.facing
	if _cool > 0:
		_cool -= 1

	# ---- keep combos going
	if me.state == Fighter.ATTACK:
		if me.connected and me.move.get("next", "") != "" and rng.randf() < combo_p * 0.25:
			inp.btn = me.move_key.substr(0, 1)
		elif me.connected and not me.move.get("skill", false) and me.move.get("next", "") == "" and rng.randf() < combo_p * 0.08:
			var s := _pick_skill(dist, o)
			if s >= 0:
				inp.btn = "s%d" % (s + 1)
		return inp

	# ---- defence: react to a seen attack
	var threat: bool = seen.state == Fighter.ATTACK and not (seen.move as Dictionary).is_empty() and seen.sf <= int(seen.move.st) + int(seen.move.act)
	var o_reach := 0.0
	if threat:
		var sm: Dictionary = seen.move
		o_reach = float(sm.get("reach", 1.0)) + Fighter.RADIUS * 2.0 + float(sm.get("lunge", 0.0)) * 0.25
		if sm.get("kind", "") in ["proj", "rain"]:
			o_reach = 99.0
	if threat and dist < o_reach + 0.5 and _block_t <= 0:
		if rng.randf() < block_p:
			_block_t = 20
			_hold_down = (seen.move as Dictionary).get("h", "mid") == "low"
			if (seen.move as Dictionary).get("unblockable", false) or rng.randf() < 0.12 * lvl:
				inp.btn = "d"     # dodge out instead
				return inp
		else:
			_block_t = -12      # committed to not blocking for a moment
	if _block_t > 0:
		_block_t -= 1
		inp.mx = away
		inp.down = _hold_down
		if o.state == Fighter.ATTACK:
			_block_t = maxi(_block_t, 4)
		return inp
	if _block_t < 0:
		_block_t += 1

	if me.state in [Fighter.HITSTUN, Fighter.BLOCKSTUN, Fighter.AIRHIT, Fighter.LYING, Fighter.GETUP, Fighter.DODGE]:
		# hold block while recovering
		inp.mx = away if rng.randf() < block_p else 0
		return inp

	# ---- offence
	var my_reach := _best_reach()
	var o_recovering: bool = o.state == Fighter.ATTACK and o.sf > int(o.move.get("st", 0)) + int(o.move.get("act", 0)) and o.move.get("kind", "") != "counter"
	var o_down: bool = o.state in [Fighter.LYING, Fighter.GETUP]
	# punish whiffs
	if o_recovering and dist < my_reach + 0.4 and rng.randf() < 0.5 + 0.4 * lvl:
		return _attack(inp, dist, o)
	# use energy
	if me.en >= 25 and _cool <= 0 and rng.randf() < 0.025 * (0.5 + aggro):
		var s := _pick_skill(dist, o)
		if s >= 0:
			inp.btn = "s%d" % (s + 1)
			_cool = 40
			return inp
	if o_down:
		# wait outside wake-up range or approach
		if dist > my_reach + 0.6:
			inp.mx = toward
		return inp
	# throw a turtling opponent
	if dist < 1.15 and o.is_blocking() and rng.randf() < 0.06 + 0.1 * lvl:
		inp.mx = toward
		inp.btn = "d"
		return inp
	if _plan_t > 0:
		_plan_t -= 1
	else:
		_new_plan(dist, my_reach)
	match _plan:
		"approach":
			inp.mx = toward
			if dist <= my_reach:
				_plan_t = 0
				if rng.randf() < aggro:
					return _attack(inp, dist, o)
		"retreat":
			inp.mx = away
		"wait":
			inp.mx = away if rng.randf() < block_p * 0.5 else 0
			if dist <= my_reach and rng.randf() < aggro * 0.12:
				return _attack(inp, dist, o)
		"jumpin":
			inp.mx = toward
			if me.grounded() and dist < 3.2 and dist > 1.2:
				inp.up = true
				_plan = "airatk"
				_plan_t = 30
		"airatk":
			inp.mx = toward
			if me.state == Fighter.JUMP and absf(o.x - me.x) < 1.5 and me.vy < 2.0:
				inp.btn = "k" if rng.randf() < 0.5 else "p"
		"zone":
			# ranged sects throw from distance
			inp.mx = away if dist < 3.0 else 0
			if dist > 2.5 and rng.randf() < 0.05:
				inp.mx = toward
				inp.btn = "p"
				_plan_t = 0
	return inp

func _new_plan(dist: float, reach: float) -> void:
	var r := rng.randf()
	var ranged: bool = me.moves.get("fp", {}).get("kind", "") == "proj"
	if ranged and r < 0.35:
		_plan = "zone"
		_plan_t = rng.randi_range(40, 90)
	elif dist > reach + 0.3 and r < 0.75:
		_plan = "approach"
		_plan_t = rng.randi_range(20, 60)
	elif r < 0.12 * (0.5 + aggro):
		_plan = "jumpin"
		_plan_t = 40
	elif r < 0.85 - aggro * 0.3:
		_plan = "wait"
		_plan_t = rng.randi_range(10, 40)
	else:
		_plan = "retreat"
		_plan_t = rng.randi_range(10, 25)

func _sealed() -> bool:
	return me.seal[0] > 0 or me.seal[1] > 0 or me.seal[2] > 0

func _best_reach() -> float:
	return float(me.moves.p1.reach) + Fighter.RADIUS * 2.0

func _attack(inp: Dictionary, dist: float, o: Fighter) -> Dictionary:
	var r := rng.randf()
	var reach := _best_reach()
	if o.crouching() or r < 0.15:
		inp.btn = "k" if r < 0.6 else "p"
		inp.down = true          # low attack
		if rng.randf() < 0.4:
			inp.down = false
			inp.btn = "k"        # overhead-ish kick chain
	elif dist > reach and r < 0.6:
		inp.mx = me.facing
		inp.btn = "p" if rng.randf() < 0.5 else "k"
	else:
		inp.btn = "p" if r < 0.65 else "k"
	return inp

func _pick_skill(dist: float, o: Fighter) -> int:
	var best := -1
	var best_score := -1.0
	for i in me.skills.size():
		if not me.skill_ready(i):
			continue
		var m: Dictionary = me.skills[i]
		var kind: String = m.get("kind", "strike")
		var score := rng.randf()
		match kind:
			"proj", "rain":
				score += 0.6 if dist > 2.0 else -0.2
			"heal":
				score += 1.0 if me.hp < me.st.hp_max * 0.5 or _sealed() else -2.0
			"buff":
				score += (0.3 if me.buffs.is_empty() else -2.0) + (2.2 if _sealed() else 0.0)
			"counter":
				score += 0.3 if o.state == Fighter.ATTACK or dist < 1.5 else -0.5
			"blink":
				score += 0.4 if dist > 2.0 else 0.0
			_:
				var reach: float = float(m.reach) + Fighter.RADIUS * 2.0 + float(m.get("lunge", 0.0)) * 0.3
				score += 0.7 if dist <= reach else -1.0
		if m.get("ult", false):
			score += 0.5
		if score > best_score:
			best_score = score
			best = i
	return best if best_score > 0.2 else -1
