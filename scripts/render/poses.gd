class_name Poses
extends RefCounted
## Pose library. Conventions (degrees, parent space, see Body):
##  limbs: +Z swings forward, knees bend with -Z, elbows bend with +Z
##  torso/head: -Z leans forward, +Y twists the left shoulder back
##  arms: sh_r +X pulls the right arm toward the centre line, sh_l -X likewise

static func v(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)

## Legs for a bow stance (front = left leg). depth 0..1 lowers the stance.
static func legs_bow(d := 1.0) -> Dictionary:
	return {
		"hip_l": v(-4, 0, 34 * d), "kn_l": v(0, 0, -46 * d), "an_l": v(0, 0, 12 * d),
		"hip_r": v(4, 0, -24 * d), "kn_r": v(0, 0, -4 * d), "an_r": v(0, 0, 28 * d),
		"root": v(-0.03 * d, -0.11 * d, 0),
	}

static func legs_horse() -> Dictionary:
	return {
		"hip_l": v(-22, 0, 30), "kn_l": v(0, 0, -60), "an_l": v(0, 0, 30),
		"hip_r": v(22, 0, -10), "kn_r": v(0, 0, -45), "an_r": v(0, 0, 55),
		"root": v(0, -0.2, 0),
	}

static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := a.duplicate()
	for k in b:
		o[k] = b[k]
	return o

## Offset every listed joint by delta (adds to a copy).
static func add(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := a.duplicate()
	for k in b:
		o[k] = (o.get(k, Vector3.ZERO) as Vector3) + (b[k] as Vector3)
	return o

# ----------------------------------------------------------------- stances
static func stance(style: String) -> Dictionary:
	match style:
		"fist":
			return merge(legs_bow(), {
				"pelvis": v(0, 10, 0), "spine": v(0, -6, -6), "chest": v(0, -6, -2), "neck": v(0, 8, 6), "head": v(0, 0, 2),
				"sh_l": v(-14, 0, 58), "el_l": v(0, 0, 78), "wr_l": v(0, 0, 10),
				"sh_r": v(16, 0, 30), "el_r": v(0, 0, 112), "wr_r": v(0, 0, 10),
			})
		"palm":
			return merge(legs_horse(), {
				"pelvis": v(0, 0, 0), "spine": v(0, 0, -4), "chest": v(0, 10, 0), "neck": v(0, -8, 4),
				"sh_l": v(-10, 0, 70), "el_l": v(0, 0, 40), "wr_l": v(0, 0, 70),
				"sh_r": v(20, 0, 20), "el_r": v(0, 0, 100), "wr_r": v(0, 0, 60),
			})
		"sword":
			return merge(legs_bow(0.85), {
				"pelvis": v(0, -8, 0), "spine": v(0, 0, -4), "chest": v(0, 8, 0), "neck": v(0, -4, 4),
				"sh_r": v(8, 0, 62), "el_r": v(0, 0, 18), "wr_r": v(0, 0, 30),
				"sh_l": v(-30, 0, -20), "el_l": v(0, 0, 140), "wr_l": v(0, 0, 20),
			})
		"staff":
			return merge(legs_bow(1.0), {
				"pelvis": v(0, 6, 0), "spine": v(0, 0, -8), "chest": v(0, 0, -2), "neck": v(0, 0, 8),
				"sh_r": v(10, 0, 8), "el_r": v(0, 0, 62), "wr_r": v(0, 0, 32),
				"sh_l": v(-6, 0, 52), "el_l": v(0, 0, 36), "wr_l": v(0, 0, 0),
			})
		"dual":
			return merge(legs_bow(0.7), {
				"pelvis": v(0, 4, 0), "spine": v(0, 0, -6), "chest": v(0, -4, 0), "neck": v(0, 4, 6),
				"sh_r": v(10, 0, 40), "el_r": v(0, 0, 70), "wr_r": v(0, 0, 40),
				"sh_l": v(-16, 0, 70), "el_l": v(0, 0, 30), "wr_l": v(0, 0, 20),
			})
		"dagger":
			return merge(legs_horse(), {
				"root": v(0, -0.25, 0),
				"pelvis": v(0, 10, 0), "spine": v(0, 0, -16), "chest": v(0, 0, -6), "neck": v(0, 0, 16),
				"sh_r": v(14, 0, 30), "el_r": v(0, 0, 80), "wr_r": v(0, 0, 50),
				"sh_l": v(-10, 0, 70), "el_l": v(0, 0, 50), "wr_l": v(0, 0, 10),
			})
		"saber":
			return merge(legs_bow(0.9), {
				"pelvis": v(0, 0, 0), "spine": v(0, 0, -6), "chest": v(0, 6, 0), "neck": v(0, -4, 6),
				"sh_r": v(4, 0, 30), "el_r": v(0, 0, 70), "wr_r": v(0, 0, 50),
				"sh_l": v(-14, 0, 50), "el_l": v(0, 0, 90), "wr_l": v(0, 0, 0),
			})
		"spear":
			return merge(legs_bow(1.0), {
				"pelvis": v(0, 10, 0), "spine": v(0, 0, -6), "chest": v(0, 0, 0), "neck": v(0, 0, 6),
				"sh_r": v(12, 0, -4), "el_r": v(0, 0, 70), "wr_r": v(0, 0, 18),
				"sh_l": v(-8, 0, 56), "el_l": v(0, 0, 28), "wr_l": v(0, 0, 0),
			})
	return stance("fist")

# ------------------------------------------------------------------- moves
## Named key poses used by move definitions. `style` lets weapon sects reuse
## arm positions with their own stance as the base.
static func key(name: String, style: String) -> Dictionary:
	var s := stance(style)
	match name:
		# ---- hand techniques
		"jab_w":
			return add(s, {"chest": v(0, 12, 0), "sh_l": v(0, 0, -20), "el_l": v(0, 0, 30)})
		"jab":
			return merge(s, {"chest": v(0, -22, 0), "sh_l": v(-10, 0, 90), "el_l": v(0, 0, 4), "root": v(0.06, -0.12, 0)})
		"cross_w":
			return add(s, {"chest": v(0, -14, 0), "sh_r": v(0, 0, -10)})
		"cross":
			return merge(s, {"chest": v(0, 30, -4), "pelvis": v(0, 22, 0), "sh_r": v(12, 0, 92), "el_r": v(0, 0, 4), "sh_l": v(-10, 0, 30), "el_l": v(0, 0, 110), "root": v(0.1, -0.12, 0)})
		"upper_w":
			return add(s, {"root": v(0, -0.08, 0), "chest": v(0, 0, -12), "sh_r": v(0, 0, -30), "el_r": v(0, 0, -20)})
		"upper":
			return merge(s, {"root": v(0.04, -0.02, 0), "spine": v(0, 0, 8), "chest": v(0, 26, 4), "sh_r": v(10, 0, 150), "el_r": v(0, 0, 40)})
		"palm_w":
			return add(s, {"chest": v(0, -20, 6), "sh_r": v(0, 0, -30), "el_r": v(0, 0, 40)})
		"palm":
			return merge(s, {"chest": v(0, 28, -6), "pelvis": v(0, 20, 0), "sh_r": v(10, 0, 88), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 80), "sh_l": v(-10, 0, 82), "el_l": v(0, 0, 4), "wr_l": v(0, 0, 80), "root": v(0.12, -0.16, 0)})
		"dpalm_w":
			return add(s, {"root": v(-0.06, -0.04, 0), "chest": v(0, 0, 12), "sh_r": v(0, 0, -40), "sh_l": v(0, 0, -50)})
		"dpalm":
			return merge(legs_bow(1.2), {"spine": v(0, 0, -14), "chest": v(0, 0, -6), "neck": v(0, 0, 14), "sh_r": v(8, 0, 96), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 80), "sh_l": v(-8, 0, 96), "el_l": v(0, 0, 0), "wr_l": v(0, 0, 80), "root": v(0.16, -0.16, 0)})
		# ---- kicks
		"fkick_w":
			return merge(s, {"hip_r": v(0, 0, 60), "kn_r": v(0, 0, -100), "an_r": v(0, 0, 20), "hip_l": v(0, 0, 0), "kn_l": v(0, 0, -10), "an_l": v(0, 0, 10), "root": v(0, -0.02, 0), "spine": v(0, 0, 6)})
		"fkick":
			return merge(s, {"hip_r": v(0, 0, 95), "kn_r": v(0, 0, -6), "an_r": v(0, 0, -20), "hip_l": v(0, 0, -8), "kn_l": v(0, 0, -10), "an_l": v(0, 0, 18), "spine": v(0, 0, 14), "chest": v(0, 0, 4), "root": v(-0.05, -0.04, 0), "sh_l": v(-30, 0, -20), "el_l": v(0, 0, 60), "sh_r": v(30, 0, -10)})
		"skick_w":
			return merge(s, {"pelvis": v(0, -40, 0), "hip_l": v(0, 0, 70), "kn_l": v(0, 0, -110), "an_l": v(0, 0, 30), "hip_r": v(0, 0, -6), "kn_r": v(0, 0, -16), "an_r": v(0, 0, 22), "spine": v(0, 0, 10)})
		"skick":
			return merge(s, {"pelvis": v(0, -50, 10), "hip_l": v(0, 0, 100), "kn_l": v(0, 0, -4), "an_l": v(0, 0, -10), "hip_r": v(0, 0, -10), "kn_r": v(0, 0, -12), "an_r": v(0, 0, 22), "spine": v(0, 30, 20), "chest": v(0, 20, 6), "neck": v(0, -30, -10), "root": v(-0.02, -0.04, 0), "sh_l": v(-20, 0, 40)})
		"round_w":
			return merge(s, {"pelvis": v(0, 40, 0), "chest": v(0, 30, 0), "hip_r": v(-30, 0, 40), "kn_r": v(0, 0, -90), "root": v(0, 0, 0)})
		"round":
			return merge(s, {"pelvis": v(0, 80, 0), "spine": v(-20, 0, 10), "chest": v(0, 20, 0), "hip_r": v(-70, 0, 70), "kn_r": v(0, 0, -10), "an_r": v(0, 0, -20), "hip_l": v(0, 0, -6), "kn_l": v(0, 0, -14), "an_l": v(0, 0, 20), "sh_l": v(-40, 0, 20), "root": v(0, -0.02, 0)})
		"sweep_w":
			return merge(legs_horse(), {"root": v(0, -0.45, 0), "spine": v(0, 0, -20), "sh_l": v(-20, 0, 40), "sh_r": v(30, 0, -20), "hip_r": v(30, 0, 40), "kn_r": v(0, 0, -100)})
		"sweep":
			return merge(s, {"root": v(-0.1, -0.5, 0), "pelvis": v(0, 30, 0), "spine": v(0, 0, -30), "chest": v(0, 0, -10), "neck": v(0, 0, 20),
				"hip_l": v(-10, 0, 70), "kn_l": v(0, 0, -140), "an_l": v(0, 0, 50),
				"hip_r": v(-20, 0, 80), "kn_r": v(0, 0, -6), "an_r": v(0, 0, -20), "sh_l": v(0, 0, 10), "el_l": v(0, 0, 20), "sh_r": v(10, 0, -40)})
		"lowpunch":
			return merge(s, {"root": v(0.05, -0.38, 0), "spine": v(0, 0, -20), "neck": v(0, 0, 14), "hip_l": v(0, 0, 80), "kn_l": v(0, 0, -110), "an_l": v(0, 0, 30), "hip_r": v(0, 0, -40), "kn_r": v(0, 0, -60), "an_r": v(0, 0, 90),
				"chest": v(0, 20, 0), "sh_r": v(16, 0, 70), "el_r": v(0, 0, 0)})
		# ---- weapon cuts (right hand)
		"slash_hi_w":
			return add(s, {"chest": v(0, -20, 10), "sh_r": v(-20, 0, 110), "el_r": v(0, 0, 40), "wr_r": v(0, 0, 40)})
		"slash_hi":
			return merge(s, {"chest": v(0, 24, -14), "spine": v(0, 0, -6), "sh_r": v(10, 0, 70), "el_r": v(0, 0, 0), "wr_r": v(0, 0, -10), "root": v(0.12, -0.16, 0)})
		"slash_h_w":
			return add(s, {"chest": v(0, -30, 0), "sh_r": v(-60, 0, 30), "el_r": v(0, 0, 40), "wr_r": v(0, 0, 30)})
		"slash_h":
			return merge(s, {"chest": v(0, 40, -4), "pelvis": v(0, 20, 0), "sh_r": v(40, 0, 80), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 10), "root": v(0.1, -0.14, 0)})
		"thrust_w":
			return add(s, {"chest": v(0, -20, 6), "sh_r": v(0, 0, -50), "el_r": v(0, 0, 60), "wr_r": v(0, 0, 10), "root": v(-0.06, 0, 0)})
		"thrust":
			return merge(legs_bow(1.25), {"spine": v(0, 0, -12), "chest": v(0, 30, -4), "neck": v(0, -20, 14), "sh_r": v(12, 0, 88), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 0), "sh_l": v(-40, 0, -30), "el_l": v(0, 0, 120), "root": v(0.2, -0.17, 0)})
		"rising_w":
			return add(s, {"root": v(0, -0.1, 0), "sh_r": v(0, 0, -60), "el_r": v(0, 0, -10), "wr_r": v(0, 0, 0)})
		"rising":
			return merge(s, {"root": v(0.04, 0.02, 0), "spine": v(0, 0, 10), "chest": v(0, 30, 6), "sh_r": v(0, 0, 175), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 0)})
		"spin":
			return merge(s, {"pelvis": v(0, 180, 0), "chest": v(0, 20, 0), "sh_r": v(70, 0, 90), "el_r": v(0, 0, 0), "sh_l": v(-70, 0, -90), "root": v(0, -0.08, 0)})
		# ---- staff
		"staff_over_w":
			return merge(s, {"spine": v(0, 0, 10), "sh_r": v(0, 0, 170), "el_r": v(0, 0, 20), "wr_r": v(0, 0, 50), "sh_l": v(0, 0, 160), "el_l": v(0, 0, 10)})
		"staff_over":
			return merge(legs_bow(1.2), {"spine": v(0, 0, -20), "chest": v(0, 0, -10), "neck": v(0, 0, 20), "sh_r": v(10, 0, 70), "el_r": v(0, 0, 10), "wr_r": v(0, 0, 20), "sh_l": v(-10, 0, 70), "el_l": v(0, 0, 0), "root": v(0.14, -0.16, 0)})
		"staff_poke_w":
			return add(s, {"sh_r": v(0, 0, -30), "el_r": v(0, 0, 20), "root": v(-0.08, 0, 0)})
		"staff_poke":
			return merge(legs_bow(1.2), {"spine": v(0, 0, -10), "chest": v(0, 20, 0), "sh_r": v(10, 0, 60), "el_r": v(0, 0, 30), "wr_r": v(0, 0, 0), "sh_l": v(-10, 0, 80), "el_l": v(0, 0, 0), "root": v(0.22, -0.15, 0)})
		"staff_sweep_w":
			return add(s, {"root": v(0, -0.15, 0), "chest": v(0, -40, 0), "sh_r": v(-40, 0, 0)})
		"staff_sweep":
			return merge(legs_horse(), {"root": v(0.04, -0.3, 0), "spine": v(0, 0, -20), "chest": v(0, 40, 0), "sh_r": v(40, 0, 60), "el_r": v(0, 0, 30), "wr_r": v(0, 0, 60), "sh_l": v(-10, 0, 60)})
		# ---- throws / projectiles
		"toss_w":
			return add(s, {"chest": v(0, -30, 10), "sh_r": v(-20, 0, 120), "el_r": v(0, 0, 50)})
		"toss":
			return merge(s, {"chest": v(0, 30, -10), "sh_r": v(10, 0, 95), "el_r": v(0, 0, 0), "wr_r": v(0, 0, -20), "root": v(0.06, 0, 0)})
		"grab":
			return merge(s, {"chest": v(0, 0, -10), "sh_r": v(10, 0, 80), "el_r": v(0, 0, 20), "sh_l": v(-10, 0, 80), "el_l": v(0, 0, 20), "root": v(0.1, -0.1, 0)})
		"heave":
			return merge(legs_bow(1.0), {"spine": v(0, 0, 20), "chest": v(0, 0, 10), "neck": v(0, 0, -10), "sh_r": v(0, 0, 170), "el_r": v(0, 0, 10), "sh_l": v(0, 0, 170), "el_l": v(0, 0, 10), "root": v(-0.05, -0.05, 0)})
		"cast_w":
			return merge(legs_horse(), {"chest": v(0, 0, 10), "sh_r": v(20, 0, 30), "el_r": v(0, 0, 120), "sh_l": v(-20, 0, 30), "el_l": v(0, 0, 120), "wr_r": v(0, 0, 40), "wr_l": v(0, 0, 40)})
		"cast":
			return merge(legs_bow(1.2), {"spine": v(0, 0, -10), "chest": v(0, 0, -6), "sh_r": v(4, 0, 90), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 80), "sh_l": v(-4, 0, 90), "el_l": v(0, 0, 0), "wr_l": v(0, 0, 80), "root": v(0.16, -0.16, 0)})
		# ---- air
		"jkick":
			return {"pelvis": v(0, -30, 20), "spine": v(0, 20, 14), "chest": v(0, 10, 0), "neck": v(0, -20, -10),
				"hip_l": v(0, 0, 100), "kn_l": v(0, 0, 0), "an_l": v(0, 0, -10), "hip_r": v(0, 0, 10), "kn_r": v(0, 0, -110), "an_r": v(0, 0, 20),
				"sh_l": v(-30, 0, 40), "el_l": v(0, 0, 60), "sh_r": v(30, 0, -30), "el_r": v(0, 0, 50)}
		"jpunch":
			return {"spine": v(0, 0, -10), "chest": v(0, 24, -6), "hip_l": v(0, 0, 50), "kn_l": v(0, 0, -100), "hip_r": v(0, 0, 20), "kn_r": v(0, 0, -110), "an_r": v(0, 0, 20),
				"sh_r": v(10, 0, 70), "el_r": v(0, 0, 0), "wr_r": v(0, 0, 0), "sh_l": v(-20, 0, 30), "el_l": v(0, 0, 100)}
	return s

# --------------------------------------------------------- reaction poses
static func jump(style: String) -> Dictionary:
	var s := stance(style)
	return merge(s, {"hip_l": v(0, 0, 70), "kn_l": v(0, 0, -120), "an_l": v(0, 0, 20), "hip_r": v(0, 0, 30), "kn_r": v(0, 0, -100), "an_r": v(0, 0, 30), "root": v(0, 0, 0), "spine": v(0, 0, -8)})

static func crouch(style: String) -> Dictionary:
	var s := stance(style)
	return merge(s, {"root": v(-0.02, -0.4, 0), "spine": v(0, 0, -14), "neck": v(0, 0, 12),
		"hip_l": v(-10, 0, 80), "kn_l": v(0, 0, -120), "an_l": v(0, 0, 40),
		"hip_r": v(10, 0, 10), "kn_r": v(0, 0, -110), "an_r": v(0, 0, 100)})

static func block(style: String, crouching: bool) -> Dictionary:
	var s := crouch(style) if crouching else stance(style)
	var weapon := style in ["sword", "staff", "saber", "spear", "dual", "dagger"]
	if weapon:
		return merge(s, {"chest": v(0, 0, 8), "sh_r": v(10, 0, 70), "el_r": v(0, 0, 70), "wr_r": v(0, 0, 50), "sh_l": v(-10, 0, 60), "el_l": v(0, 0, 90)})
	return merge(s, {"chest": v(0, 0, 8), "sh_r": v(30, 0, 60), "el_r": v(0, 0, 120), "sh_l": v(-30, 0, 70), "el_l": v(0, 0, 115), "neck": v(0, 0, -6)})

static func hurt(style: String, heavy: bool) -> Dictionary:
	var s := stance(style)
	var k := 1.6 if heavy else 1.0
	return add(s, {"spine": v(0, 0, 14 * k), "chest": v(0, 0, 12 * k), "neck": v(0, 0, 20 * k), "sh_r": v(0, 0, -30 * k), "sh_l": v(0, 0, -40 * k), "root": v(-0.05, 0.02, 0)})

static func hurt_low(style: String) -> Dictionary:
	var s := stance(style)
	return add(s, {"spine": v(0, 0, -24), "chest": v(0, 0, -10), "neck": v(0, 0, -10), "root": v(0, -0.08, 0), "sh_r": v(0, 0, 20), "sh_l": v(0, 0, 20)})

static func airborne_hurt() -> Dictionary:
	return {"pelvis": v(0, 0, 40), "spine": v(0, 0, 20), "chest": v(0, 0, 10), "neck": v(0, 0, 20),
		"hip_l": v(0, 0, 50), "kn_l": v(0, 0, -50), "hip_r": v(0, 0, 20), "kn_r": v(0, 0, -30),
		"sh_l": v(-40, 0, -60), "el_l": v(0, 0, 30), "sh_r": v(40, 0, -50), "el_r": v(0, 0, 40)}

static func lying() -> Dictionary:
	return {"pelvis": v(0, 0, 90), "root": v(0, -0.82, 0), "spine": v(0, 0, 4), "neck": v(0, 0, -10), "head": v(10, 30, 0),
		"hip_l": v(-8, 0, 10), "kn_l": v(0, 0, -20), "an_l": v(0, 0, -60), "hip_r": v(10, 0, 30), "kn_r": v(0, 0, -50), "an_r": v(0, 0, -50),
		"sh_l": v(-70, 0, -10), "el_l": v(0, 0, 30), "sh_r": v(80, 0, 10), "el_r": v(0, 0, 50)}

static func getup(style: String) -> Dictionary:
	return merge(crouch(style), {"spine": v(0, 0, -30), "sh_r": v(10, 0, 40), "sh_l": v(-10, 0, 40)})

static func dodge(style: String) -> Dictionary:
	var s := stance(style)
	return merge(s, {"root": v(-0.15, -0.3, 0), "spine": v(0, 0, 20), "chest": v(0, 0, 10), "neck": v(0, 0, -10),
		"hip_l": v(0, 0, 60), "kn_l": v(0, 0, -100), "an_l": v(0, 0, 40), "hip_r": v(0, 0, -40), "kn_r": v(0, 0, -60), "an_r": v(0, 0, 100)})

static func victory(style: String) -> Dictionary:
	var s := stance(style)
	var weapon := style in ["sword", "staff", "saber", "spear", "dual", "dagger"]
	var legs := {"hip_l": v(-4, 0, 4), "kn_l": v(0, 0, -4), "an_l": v(0, 0, 0), "hip_r": v(4, 0, -4), "kn_r": v(0, 0, 0), "an_r": v(0, 0, 4), "root": v(0, 0, 0)}
	if weapon:
		return merge(s, merge(legs, {"spine": v(0, 0, 0), "chest": v(0, -20, 0), "sh_r": v(30, 0, 10), "el_r": v(0, 0, 10), "wr_r": v(0, 0, 0), "sh_l": v(-20, 0, 60), "el_l": v(0, 0, 120), "neck": v(0, 30, 0)}))
	# fist-in-palm salute (bao quyền)
	return merge(s, merge(legs, {"spine": v(0, 0, 0), "chest": v(0, 0, 0), "sh_r": v(30, 0, 50), "el_r": v(0, 0, 90), "wr_r": v(0, 0, 0), "sh_l": v(-30, 0, 50), "el_l": v(0, 0, 90), "neck": v(0, 0, 0)}))

static func walk(style: String, phase: float, dir: float) -> Dictionary:
	var s := stance(style)
	var a := sin(phase) * 12.0 * dir
	var b := maxf(0.0, cos(phase)) * 14.0
	var c := maxf(0.0, -cos(phase)) * 14.0
	return add(s, {"hip_l": v(0, 0, a), "kn_l": v(0, 0, -b), "hip_r": v(0, 0, -a), "kn_r": v(0, 0, -c), "root": v(0, absf(sin(phase)) * 0.025, 0)})

static func idle_breathe(style: String, t: float) -> Dictionary:
	var s := stance(style)
	var br := sin(t * 2.4)
	return add(s, {"chest": v(0, 0, br * 1.5), "sh_r": v(0, 0, br * 2.0), "sh_l": v(0, 0, -br * 2.0), "root": v(0, br * 0.008, 0)})
