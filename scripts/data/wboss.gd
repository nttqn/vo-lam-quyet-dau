class_name WBoss
extends RefCounted
## Boss Thế Giới: one giant boss a day (rotation of the 2 in LIST), every player chips at the
## same server-side health pool. A try is a 90 s fight against a towering
## boss with Bá Thể (poise; Fighter.poise_max): score = damage dealt. Each
## hero gets TRIES a day (+AD_MAX by rewarded ad). Rewards: per try (scaled
## by damage), and next day by rank on yesterday's damage board, plus a bonus
## for everyone when the pool was emptied.
##
## Firestore: wb_<yyyymmdd>/{uid}_{slot} {name, sect, level, dmg, tries};
## the pool's damage = sum(dmg) over the collection (aggregation query).
## h.wboss = {date, tries, ads, dmg, best, prev: {date, dmg}, claimed}

const TRIES := 3
const AD_MAX := 1
const MIN_LEVEL := 10
const FIGHT_SECONDS := 90
const SIZE := 1.6            # body width, reach and model height
const POISE := 16.0          # hits soaked before Phá Thế
const HP_MULT := 1.5         # boss HP in one try vs. a normal boss of the hero's level
const HIT_MULT := 0.5        # boss Công / Nội công: slow heavy giant, poise already makes it trade well
const POOL := 400000         # default shared health of the day's boss; Firestore
                             # config/wboss {pool} overrides it (tune by player count)
static var _pool_cfg := 0

## model: assets/models/chars/<model>.fbx (Meshy, see assets_src/boss/PROMPT_BOSS.md);
## until it exists the sect's model is used, recoloured by tint.
const LIST := [
	{"id": "dong_giap", "name": "Đồng Giáp La Hán", "title": "Thủ Hộ Tàng Kinh", "sect": "thieu_lam",
		"model": "Boss_DongGiap", "tint": Color(1.0, 0.72, 0.42), "theme": "temple", "aura": Color(1.0, 0.65, 0.25),
		"desc": "Pho tượng đồng ngàn năm canh giữ Tàng Kinh Các bỗng sống dậy. Côn pháp nặng như núi, đánh trúng thân đồng chỉ nghe keng keng."},
	{"id": "bang_phach", "name": "Băng Phách Kiếm Quân", "title": "Chúa Tể Tuyết Sơn", "sect": "vo_dang",
		"model": "Boss_BangPhach", "tint": Color(0.7, 0.88, 1.15), "theme": "snow", "aura": Color(0.5, 0.8, 1.0),
		"desc": "Kiếm khách bị phong ấn trong băng trăm năm, toàn thân giáp băng. Mỗi đường kiếm mang theo hàn khí thấu xương."},
]

static func collection(date := "") -> String:
	return "wb_" + (date if date != "" else Daily.today()).replace("-", "")

static func day_index(date := "") -> int:
	var d := date if date != "" else Daily.today()
	return int(Time.get_unix_time_from_datetime_string(d + "T12:00:00") / 86400)

static var test_pick := -1   # -- --wb=<i>: show / fight boss i (tests)

static func today_boss(date := "") -> Dictionary:
	if test_pick >= 0:
		return LIST[test_pick % LIST.size()]
	return LIST[posmod(day_index(date), LIST.size())]

static func ensure(h: Dictionary) -> Dictionary:
	var w: Dictionary = h.get("wboss", {})
	if not w.has("prev"):
		w["prev"] = {"date": "", "dmg": 0}
		w["claimed"] = ""
	var today := Daily.today()
	var c := Daily.cmp(str(w.get("date", "")), today)
	if c > 0:
		# ran ahead: that day's tries count for today, its damage never reached a board
		w["date"] = today
		w["dmg"] = 0
		w["best"] = 0
	elif c < 0:
		if int(w.get("dmg", 0)) > 0:
			w["prev"] = {"date": str(w.date), "dmg": int(w.dmg)}
		w["date"] = today
		w["tries"] = 0
		w["ads"] = 0
		w["dmg"] = 0
		w["best"] = 0
	h.wboss = w
	return w

static func unlocked(h: Dictionary) -> bool:
	return int(h.level) >= MIN_LEVEL

static func left(h: Dictionary) -> int:
	var w := ensure(h)
	return maxi(0, TRIES + int(w.ads) - int(w.tries))

static func can_ad(h: Dictionary) -> bool:
	return int(ensure(h).ads) < AD_MAX

static func add_ad_try(h: Dictionary) -> void:
	var w := ensure(h)
	w.ads = int(w.ads) + 1

## Yesterday's (or the last played day's) board reward not yet taken.
static func claimable(h: Dictionary) -> bool:
	var w := ensure(h)
	var p: Dictionary = w.prev
	return str(p.date) != "" and int(p.dmg) > 0 and str(w.claimed) != str(p.date) and str(p.date) < Daily.today()

## Fight side of today's boss for this hero: a normal boss of the hero's level
## (+3), much more health, harder blows, a little slower, giant and poised.
static func side(h: Dictionary, boss := {}) -> Dictionary:
	var b: Dictionary = boss if not boss.is_empty() else today_boss()
	var lvl := mini(Hero.MAX_LEVEL + 5, int(h.level))
	var e := Npc.side(b.sect, lvl, b.name, 0.62, "", true, 9000 + day_index(), b.title)
	var st: Dictionary = e.stats
	st.hp_max *= HP_MULT
	st.atk *= HIT_MULT
	st.qi *= HIT_MULT
	st.spd *= 0.88
	var lk: Dictionary = e.look
	lk["height"] = SIZE
	lk["wglow"] = 4     # cường hóa +15 glow on the boss weapon
	lk["tint"] = b.tint
	var own := str(b.model)
	lk["model"] = own if Avatar.model_path(own) != "" else str(Sects.get_sect(b.sect).look.get("model", ""))
	if lk.model == own:
		lk.erase("tint")   # the painted boss model keeps its own colours
	e["size"] = SIZE
	e["poise"] = POISE
	e["aura"] = b.aura
	return e

## Rewards of one try. ratio = share of the boss's try-health taken (0..1).
static func try_rewards(lvl: int, ratio: float, killed: bool) -> Dictionary:
	var r := clampf(ratio, 0.0, 1.0)
	var rw := {"exp": int((25 + 8 * lvl) * (0.6 + r)), "gold": int((30 + 10 * lvl) * (0.6 + r)), "jade": 0,
		"mats": {"iron": 2 + lvl / 10 + int(r * 6)}}
	if r >= 0.5:
		rw.mats["wash"] = 1
	if killed:
		rw.mats["star"] = 1
		rw.jade = 3
	return rw

## [rank limit, label, rewards] — rank -1 = unknown (offline / hidden).
const TIERS := [
	[1, "Hạng 1", {"jade": 60, "mats": {"star": 3, "wash": 3, "charm": 1}}],
	[3, "Hạng 2–3", {"jade": 40, "mats": {"star": 2, "wash": 2}}],
	[10, "Hạng 4–10", {"jade": 25, "mats": {"star": 1, "wash": 2}}],
	[50, "Hạng 11–50", {"jade": 12, "mats": {"wash": 1, "iron": 10}}],
	[999999999, "Tham gia", {"jade": 5, "mats": {"iron": 6}}],
]
const KILL_BONUS := {"jade": 10, "mats": {"star": 1, "charm": 1}}

static func tier(rank: int) -> Array:
	if rank <= 0:
		return TIERS[TIERS.size() - 1]
	for t in TIERS:
		if rank <= int(t[0]):
			return t
	return TIERS[TIERS.size() - 1]

## Day reward for a rank (+ the bonus when the pool was emptied).
static func day_rewards(rank: int, killed: bool) -> Dictionary:
	var rw: Dictionary = tier(rank)[2].duplicate(true)
	if killed:
		rw.jade = int(rw.get("jade", 0)) + int(KILL_BONUS.jade)
		for k in KILL_BONUS.mats:
			rw.mats[k] = int(rw.mats.get(k, 0)) + int(KILL_BONUS.mats[k])
	return rw

static func rewards_text(rw: Dictionary) -> String:
	var parts := []
	if int(rw.get("jade", 0)) > 0:
		parts.append(L.f("Ngọc %d", int(rw.jade)))
	var m: Dictionary = rw.get("mats", {})
	for id in Mats.IDS:
		if int(m.get(id, 0)) > 0:
			parts.append(L.f("%s %d", [Mats.name_of(id), int(m[id])]))
	return ", ".join(parts)

# ------------------------------------------------------------- cloud
static func fields(h: Dictionary) -> Dictionary:
	var w := ensure(h)
	return {"name": str(h.name).substr(0, 24), "sect": str(h.sect), "level": int(h.level),
		"dmg": int(w.dmg), "tries": int(w.tries)}

## Uploads today's damage of this hero (not while hidden from the boards).
static func publish(h: Dictionary, slot: int) -> bool:
	if not Cloud.enabled() or Ranks.hidden() or Ban.active():
		return false
	return await Cloud.put_doc(collection(), "_%d" % slot, fields(h))

## Damage the whole server dealt on that day; -1 offline.
## The day's shared health: config/wboss.pool when set, else POOL.
static func pool() -> int:
	return _pool_cfg if _pool_cfg > 0 else POOL

static func load_pool() -> void:
	if Cloud.enabled() and _pool_cfg == 0:
		_pool_cfg = int((await Cloud.get_doc("config/wboss")).get("pool", 0))

static func pool_dmg(date := "") -> int:
	if not Cloud.enabled():
		return -1
	return await Cloud.sum_field(collection(date), "dmg")

## Top damage dealers of that day.
static func board(date := "", n := 30) -> Array:
	if not Cloud.enabled():
		return []
	return await Cloud.query(collection(date), "dmg", n)

## This hero's rank on that day's board (by its damage); -1 unknown.
static func rank_of(dmg: int, date := "") -> int:
	if not Cloud.enabled() or Ranks.hidden() or Ban.active() or dmg <= 0:
		return -1
	var above := await Cloud.count_above(collection(date), "dmg", dmg)
	return above + 1 if above >= 0 else -1

## Takes the last played day's reward: looks up rank and whether the pool fell.
## Returns {rank, killed, rewards} or {} when nothing to claim.
static func claim(h: Dictionary) -> Dictionary:
	if not claimable(h):
		return {}
	var w := ensure(h)
	var p: Dictionary = w.prev
	var rank := await rank_of(int(p.dmg), str(p.date))
	var total := await pool_dmg(str(p.date))
	await load_pool()
	var killed := total >= pool()
	if not claimable(h):   # claimed meanwhile (double tap)
		return {}
	var rw := day_rewards(rank, killed)
	w.claimed = str(p.date)
	h.jade = int(h.jade) + int(rw.get("jade", 0))
	Mats.give(h, rw.get("mats", {}))
	return {"rank": rank, "killed": killed, "rewards": rw}
