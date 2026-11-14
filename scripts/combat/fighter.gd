class_name Fighter
extends RefCounted
## Pure fight logic for one combatant (no nodes). Runs at 60 ticks/s.

enum { IDLE, WALK, CROUCH, JUMP, ATTACK, BLOCKSTUN, HITSTUN, AIRHIT, LYING, GETUP, DODGE, DASH, THROWN, KO, WIN, LAND }

const DT := 1.0 / 60.0
const GRAV := 30.0
const JUMP_V := 9.6
const WALK_SPD := 2.7
const BACK_SPD := 2.1
const RADIUS := 0.32
const EN_MAX := 100.0
# Điểm huyệt: hits fill pressure on a zone; at SEAL_AT the zone is sealed.
#   0 tay (arms: weaker blows)  1 chân (legs: slow, no jump/dash)
#   2 đan điền (qi: no energy gain, no ultimate)
const ZONE_NAMES := ["Tay", "Chân", "Đan Điền"]
const SEAL_AT := 100.0
const SEAL_FRAMES := 300
const PRESS_DECAY := 9.0        # per second while not sealed

var idx := 0
var name := ""
var title := ""
var sect: Dictionary
var style := "fist"
var moves: Dictionary
var skills: Array = []          # up to 3 skill dicts (equipped)
var st := {}                    # hp_max, atk, def, qi, spd, crit, en_gain, dodge
var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var facing := 1
var hp := 100.0
var en := 0.0
var state := IDLE
var sf := 0                     # frames in state
var stun := 0
var move: Dictionary = {}
var move_key := ""
var hits_done := 0
var connected := false          # current move hit or was blocked
var whiffed_sent := false
var buf_btn := ""
var buf_t := 0
var hold_back := false
var hold_down := false
var mx := 0
var inv := 0
var armor_left := 0
var cds := {}                   # skill index -> frames
var buffs: Array = []           # {k: "atk"/"def"/"spd"/"armor"/"regen_en", v, t}
var poison_t := 0
var poison_dps := 0.0
var combo_taken := 0
var juggle := 0
var hit_low := false
var dodge_cd := 0
var air_attacked := false
var dead := false
var ko_time := 0
var stats_dealt := 0.0
var max_combo := 0
var _combo_run := 0
var press := [0.0, 0.0, 0.0]    # pressure per zone
var seal := [0, 0, 0]           # frames left sealed per zone
var insight_sent := false       # this move already taught the defender once
var last_hit := ""              # name of the move that last damaged this fighter

func setup(p_sect: Dictionary, p_stats: Dictionary, p_skills: Array) -> void:
	sect = p_sect
	style = sect.style
	moves = sect.moves
	st = p_stats
	skills = p_skills
	hp = st.hp_max
	en = 0.0

func reset_round(px: float, face: int) -> void:
	x = px
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = face
	hp = st.hp_max
	en = minf(en, EN_MAX)
	state = IDLE
	sf = 0
	stun = 0
	move = {}
	buffs.clear()
	poison_t = 0
	inv = 0
	dead = false
	combo_taken = 0
	cds.clear()
	buf_btn = ""
	press = [0.0, 0.0, 0.0]
	seal = [0, 0, 0]
	last_hit = ""

# ------------------------------------------------------------- queries
func grounded() -> bool:
	return y <= 0.0001 and state != AIRHIT and state != JUMP

func is_free() -> bool:
	return state in [IDLE, WALK, CROUCH, LAND] and not dead

func crouching() -> bool:
	return state == CROUCH or (state == BLOCKSTUN and hold_down) or (state == ATTACK and move.get("h", "") == "low" and not move.get("air", false))

func is_blocking() -> bool:
	return hold_back and (state in [IDLE, WALK, CROUCH, BLOCKSTUN]) and grounded()

func buff_mult(k: String) -> float:
	var v := 1.0
	for b in buffs:
		if b.k == k:
			v *= b.v
	return v

func has_buff(k: String) -> bool:
	for b in buffs:
		if b.k == k:
			return true
	return false

func speed_mult() -> float:
	return float(sect.get("speed", 1.0)) * st.get("spd", 1.0) * buff_mult("spd") * (0.7 if seal[1] > 0 else 1.0)

func sealed(z: int) -> bool:
	return seal[z] > 0

## Energy gain multiplier (đan điền sealed: qi stops flowing).
func en_mult() -> float:
	return 0.2 if seal[2] > 0 else 1.0

## Zone a move strikes: its own "seal" target, else by height.
static func zone_of(m: Dictionary) -> int:
	var s: String = m.get("seal", "")
	if s != "":
		return ["tay", "chan", "dan"].find(s)
	match str(m.get("h", "mid")):
		"low": return 1
		"high", "over": return 0
	return 2

## Pressure from a landed hit; returns the zone if it just got sealed, else -1.
func add_press(m: Dictionary) -> int:
	var z := zone_of(m)
	if z < 0 or seal[z] > 0:
		return -1
	var amt: float
	if m.get("seal", "") != "":
		amt = float(m.get("seal_amt", 75.0)) / maxf(1.0, float(m.get("hits", 1)))
	else:
		amt = 12.0 * float(m.dmg) * (1.2 if m.get("skill", false) else 1.0)
	press[z] += amt
	if press[z] >= SEAL_AT:
		press[z] = 0.0
		seal[z] = SEAL_FRAMES
		return z
	return -1

## Giải huyệt: buff / heal techniques clear every seal and pressure.
func clear_seals() -> bool:
	var had: bool = seal[0] > 0 or seal[1] > 0 or seal[2] > 0
	press = [0.0, 0.0, 0.0]
	seal = [0, 0, 0]
	return had

func move_total() -> int:
	return move.st + move.act + move.rec

func in_active() -> bool:
	return state == ATTACK and sf >= move.st and sf < move.st + move.act

func skill_ready(i: int) -> bool:
	if i >= skills.size() or skills[i] == null:
		return false
	var m: Dictionary = skills[i]
	if m.get("ult", false) and seal[2] > 0:
		return false
	return en >= m.cost and int(cds.get(i, 0)) <= 0

# ------------------------------------------------------------- input
## inp: {mx:int, up:bool, down:bool, btn:String}
func think(inp: Dictionary, opp: Fighter, sim) -> void:
	mx = inp.get("mx", 0)
	hold_down = inp.get("down", false)
	hold_back = mx != 0 and mx == -facing
	var b: String = inp.get("btn", "")
	if b != "":
		buf_btn = b
		buf_t = 9
	elif buf_t > 0:
		buf_t -= 1
		if buf_t == 0:
			buf_btn = ""
	if dead:
		return
	match state:
		IDLE, WALK, CROUCH, LAND:
			if state == LAND and sf < 4:
				return
			if grounded() and opp.state != THROWN:
				facing = 1 if opp.x >= x else -1
			hold_back = mx != 0 and mx == -facing
			if buf_btn != "" and _try_button(buf_btn, opp, sim):
				return
			if inp.get("up", false) and seal[1] <= 0:
				set_state(JUMP)
				vy = JUMP_V
				vx = mx * WALK_SPD * 1.15 * speed_mult()
				air_attacked = false
				return
			if hold_down:
				if state != CROUCH:
					set_state(CROUCH)
				vx = 0.0
				return
			if mx != 0:
				if state != WALK:
					set_state(WALK)
				vx = mx * (BACK_SPD if hold_back else WALK_SPD) * speed_mult()
			else:
				if state != IDLE:
					set_state(IDLE)
				vx = 0.0
		JUMP:
			if buf_btn in ["p", "k"] and not air_attacked:
				var key := "jp" if buf_btn == "p" else "jk"
				if moves.has(key):
					air_attacked = true
					_consume()
					_start_move(key, moves[key], sim)
		ATTACK:
			# chain cancels
			if connected and buf_btn != "" and sf >= move.st + 1:
				var nxt: String = move.get("next", "")
				if buf_btn == move_key.substr(0, 1) and nxt != "" and moves.has(nxt):
					_consume()
					_start_move(nxt, moves[nxt], sim)
				elif buf_btn.begins_with("s") and not move.get("skill", false):
					var si := int(buf_btn.substr(1)) - 1
					if skill_ready(si):
						_consume()
						_start_skill(si, sim)

func _consume() -> void:
	buf_btn = ""
	buf_t = 0

func _try_button(b: String, opp: Fighter, sim) -> bool:
	var dist := absf(opp.x - x)
	var toward := mx == facing
	match b:
		"p", "k":
			var key := b + "1"
			if hold_down:
				key = "d" + b
			elif toward:
				key = "f" + b
			if moves.has(key):
				_consume()
				_start_move(key, moves[key], sim)
				return true
		"d":
			_consume()
			if dodge_cd > 0:
				return false
			if toward and dist < 1.25 and opp.grounded() and opp.state not in [LYING, GETUP, KO, THROWN] and opp.inv == 0:
				_start_move("throw", moves["throw"], sim)
				return true
			if toward:
				if seal[1] > 0:
					return false
				set_state(DASH)
				vx = facing * 8.0 * speed_mult()
				dodge_cd = 20
			else:
				set_state(DODGE)
				vx = -facing * 7.0 * speed_mult()
				dodge_cd = 32
			return true
		"s1", "s2", "s3":
			var si := int(b.substr(1)) - 1
			_consume()
			if skill_ready(si):
				_start_skill(si, sim)
				return true
	return false

func _start_skill(i: int, sim) -> void:
	var m: Dictionary = skills[i]
	en -= m.cost
	cds[i] = m.cd
	_start_move("s%d" % (i + 1), m, sim)
	sim.emit({"t": "skill", "i": idx, "name": m.name, "ult": m.get("ult", false)})

func _start_move(key: String, m: Dictionary, sim) -> void:
	move = m
	move_key = key
	hits_done = 0
	connected = false
	whiffed_sent = false
	insight_sent = false
	armor_left = 1 if m.get("armor", false) else 0
	if m.get("ult", false):
		armor_left = 99
	if not m.get("air", false):
		set_state(ATTACK)
		vx = 0.0
	else:
		state = ATTACK
		sf = 0
	if m.get("kind", "") == "leap":
		vy = JUMP_V * 0.9
		vx = facing * 3.5
	sim.emit({"t": "swing", "i": idx, "fx": m.get("fx", "hit"), "skill": m.get("skill", false)})

func set_state(s: int) -> void:
	state = s
	sf = 0

# ------------------------------------------------------------- physics
func step(opp: Fighter, sim) -> void:
	sf += 1
	if inv > 0:
		inv -= 1
	if dodge_cd > 0:
		dodge_cd -= 1
	for k in cds.keys():
		cds[k] = int(cds[k]) - 1
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i].t -= 1
		if buffs[i].k == "regen_en":
			en = minf(EN_MAX, en + buffs[i].v * DT)
		if buffs[i].t <= 0:
			buffs.remove_at(i)
	if not dead:
		en = minf(EN_MAX, en + 1.6 * st.get("en_gain", 1.0) * en_mult() * DT)
	for z in 3:
		if seal[z] > 0:
			seal[z] -= 1
			if seal[z] == 0:
				sim.emit({"t": "unseal", "i": idx, "z": z})
		elif press[z] > 0.0:
			press[z] = maxf(0.0, press[z] - PRESS_DECAY * DT)
	if poison_t > 0 and not dead:
		poison_t -= 1
		hp -= poison_dps * DT
		if hp <= 1.0:
			hp = 1.0     # poison never kills
	match state:
		ATTACK:
			_step_attack(opp, sim)
		HITSTUN, BLOCKSTUN:
			vx *= 0.86
			if sf >= stun:
				set_state(CROUCH if hold_down else IDLE)
				combo_taken = 0 if state == IDLE or state == CROUCH else combo_taken
		DODGE:
			inv = 1 if sf < 14 else 0
			vx *= 0.9
			if sf >= 20:
				set_state(IDLE)
		DASH:
			vx *= 0.93
			if sf >= 14:
				set_state(IDLE)
		LYING:
			vx *= 0.8
			inv = 2
			if dead:
				pass
			elif sf >= 36:
				set_state(GETUP)
		GETUP:
			inv = 2
			if sf >= 18:
				set_state(IDLE)
				combo_taken = 0
				juggle = 0
		THROWN:
			inv = 0
		WIN:
			vx = 0.0
		LAND:
			vx *= 0.7
			if sf >= 5:
				set_state(IDLE)
	# integrate
	var airborne := y > 0.0 or vy > 0.0
	if airborne and state != THROWN:
		vy -= GRAV * DT
	x += vx * DT
	y += vy * DT
	if y <= 0.0 and (airborne):
		y = 0.0
		vy = 0.0
		_land(sim)

func _land(sim) -> void:
	match state:
		JUMP:
			set_state(LAND)
		AIRHIT:
			sim.emit({"t": "land", "i": idx, "x": x})
			set_state(LYING)
			vx *= 0.4
			if dead:
				state = KO
		ATTACK:
			if move.get("air", false) or move.get("kind", "") == "leap":
				if move.get("kind", "") == "leap" and sf < move.st + move.act:
					sf = move.st + move.act   # landing ends the dive
					return
				set_state(LAND)

func _step_attack(opp: Fighter, sim) -> void:
	var m := move
	var kind: String = m.get("kind", "strike")
	# lunge during startup+active
	if sf < m.st + m.act and m.lunge > 0.0 and kind != "leap":
		vx = facing * m.lunge * (1.0 if sf >= m.st * 0.5 else 0.5)
		# stop at the opponent instead of pushing through
		var gap := (opp.x - x) * facing
		if gap < RADIUS * 2.0 + 0.15 and gap > -0.2:
			vx = 0.0
	elif not m.get("air", false) and kind != "leap":
		vx *= 0.8
	if sf == m.st:
		match kind:
			"buff":
				var bf: Dictionary = m.buff
				for k in bf:
					if k == "t":
						continue
					buffs.append({"k": k, "v": float(bf[k]) if not (bf[k] is bool) else 1.0, "t": int(bf.t)})
				sim.emit({"t": "buff", "i": idx})
				if clear_seals():
					sim.emit({"t": "cleanse", "i": idx})
			"heal":
				var h: float = st.hp_max * m.heal * st.get("heal_mult", 1.0)
				hp = minf(st.hp_max, hp + h)
				sim.emit({"t": "heal", "i": idx, "amt": h})
				if clear_seals():
					sim.emit({"t": "cleanse", "i": idx})
			"blink":
				var nx := opp.x - facing * 0.0 + (1.0 if opp.x < x else -1.0) * -0.9
				nx = opp.x + (opp.x - x) / maxf(0.01, absf(opp.x - x)) * 0.85
				nx = clampf(nx, -sim.WALL + 0.3, sim.WALL - 0.3)
				sim.emit({"t": "blink", "i": idx, "from": x, "to": nx})
				x = nx
				facing = 1 if opp.x >= x else -1
			"proj":
				pass
			"rain":
				pass
	if kind in ["proj", "rain"] and sf >= m.st:
		var pj: Dictionary = m.proj
		var n: int = pj.get("n", 1)
		var gap: int = pj.get("gap", 1)
		var k: int = sf - int(m.st)
		if k % maxi(gap, 1) == 0 and k / maxi(gap, 1) < n:
			sim.spawn_proj(self, opp, m, k / maxi(gap, 1))
	if m.get("heal", 0.0) > 0.0 and kind == "strike" and sf == m.st:
		hp = minf(st.hp_max, hp + st.hp_max * m.heal)
		sim.emit({"t": "heal", "i": idx, "amt": st.hp_max * m.heal})
	if sf >= m.st + m.act and not connected and not whiffed_sent and kind in ["strike", "rush", "leap", "throw"]:
		whiffed_sent = true
	if sf >= move_total():
		if m.get("air", false) and y > 0.0:
			state = JUMP
			return
		set_state(CROUCH if hold_down else IDLE)

## Called by the sim when this fighter's counter stance absorbs an attack.
func trigger_counter(sim) -> void:
	sf = move.st + move.act   # skip to recovery
	inv = 20

func take_hit(att: Fighter, m: Dictionary, dmg: float, sim, crit: bool) -> void:
	_combo_run = 0
	combo_taken += 1
	poison_t = maxi(poison_t, 0)
	if m.get("poison", 0.0) > 0.0:
		poison_t = 300
		poison_dps = att.st.qi * m.poison * 0.5
	var dir := float(att.facing)
	hp -= dmg
	last_hit = str(m.get("name", ""))
	en = minf(EN_MAX, en + (4.0 + dmg / st.hp_max * 30.0) * en_mult())
	if hp > 0.0:
		var z := add_press(m)
		if z >= 0:
			sim.emit({"t": "seal", "i": idx, "z": z, "by": att.idx})
	if hp <= 0.0:
		hp = 0.0
		dead = true
		set_state(AIRHIT)
		vy = 5.5
		vx = dir * 4.0
		return
	var armored: bool = (armor_left > 0 and state == ATTACK and sf < move.st + move.act) or has_buff("armor")
	if armored and m.launch <= 0.0 and not m.kd and m.get("kind", "") != "throw":
		if armor_left > 0 and armor_left < 99:
			armor_left -= 1
		sim.emit({"t": "armor", "i": idx})
		return
	var air := y > 0.05 or state == AIRHIT
	if m.launch > 0.0 or m.kd or air or (m.get("kind", "") == "throw"):
		juggle += 1
		set_state(AIRHIT)
		var l: float = m.launch if m.launch > 0.0 else 3.2
		if air:
			l = maxf(3.5, l * 0.55) / (1.0 + juggle * 0.35)
		vy = l
		vx = dir * (absf(m.push) * 0.6 + 1.0) * (-1.0 if m.push < 0 else 1.0)
		if juggle > 3:
			vy = minf(vy, 2.0)
		return
	set_state(HITSTUN)
	stun = int(m.hs * (1.0 if combo_taken < 6 else 0.7))
	hit_low = m.h == "low"
	vx = dir * m.push
	move = {}
