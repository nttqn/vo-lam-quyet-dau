extends Node
## -- --iaptest : offline checks for 1.1.0 (no network, settings restored after).
##  - Play signature check (Iap.verify / reject_reason) with a locally made RSA key
##  - desktop fake purchases: Ngọc packs (first ×2), Gói Tân Thủ once, Bỏ QC, ô 5–6, queue
##  - Thành tựu values / claims / counters
##  - Funnel steps a hero has reached

var _fails := 0
var _n := 0

func _ok(cond: bool, what: String) -> void:
	_n += 1
	if not cond:
		_fails += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)

func _ready() -> void:
	var saved := Game.settings.duplicate(true)
	Game.slot = -1   # Game.save() writes nothing
	_sig()
	_buy()
	_ach()
	_funnel()
	Game.settings = saved
	Game.save_settings()
	print("IAPTEST %d/%d passed" % [_n - _fails, _n])
	get_tree().quit(1 if _fails > 0 else 0)

func _sig() -> void:
	var c := Crypto.new()
	var key := c.generate_rsa(2048)
	var pub := key.save_to_string(true)
	var b64 := ""
	for line in pub.split("\n"):
		if not line.begins_with("-----"):
			b64 += line.strip_edges()
	var data := '{"orderId":"GPA.1234-5678","packageName":"com.trungsmail.volamquyetdau","productId":"ngoc_60","purchaseTime":1763400000000,"purchaseState":0,"purchaseToken":"tok","quantity":1,"acknowledged":false}'
	var sig := Marshalls.raw_to_base64(c.sign(HashingContext.HASH_SHA1, data.sha1_buffer(), key))
	_ok(Iap.verify(data, sig, b64), "genuine signature verifies")
	_ok(Iap.reject_reason(data, sig, ["ngoc_60"], b64) == "", "genuine purchase accepted")
	_ok(Iap.reject_reason(data.replace("ngoc_60", "ngoc_1500"), sig, ["ngoc_1500"], b64) == "sig", "edited JSON refused (sig)")
	_ok(Iap.reject_reason(data, sig, ["ngoc_1500"], b64) == "sku", "other product id refused (sku)")
	_ok(Iap.reject_reason(data, "", ["ngoc_60"], b64) == "nosig", "missing signature refused (nosig)")
	_ok(Iap.reject_reason(data, "AAAA" + sig.substr(4), ["ngoc_60"], b64) == "sig", "bogus signature refused")
	var other := c.generate_rsa(2048).save_to_string(true)
	var ob := ""
	for line in other.split("\n"):
		if not line.begins_with("-----"):
			ob += line.strip_edges()
	_ok(Iap.reject_reason(data, sig, ["ngoc_60"], ob) == "sig", "signature by another key refused")
	_ok(Iap.reject_reason(data, "", ["ngoc_60"], "") == "", "no licence key: nothing refused")
	var pk := Iap.LICENSE_KEY
	var pem := "-----BEGIN PUBLIC KEY-----
"
	for i in range(0, pk.length(), 64):
		pem += pk.substr(i, 64) + "
"
	var ck := CryptoKey.new()
	_ok(pk != "" and ck.load_from_string(pem + "-----END PUBLIC KEY-----
", true) == OK, "Play licence key loads as an RSA public key")
	_ok(Iap.reject_reason(data, sig, ["ngoc_60"]) == "sig", "locally signed purchase refused by the real key")

func _buy() -> void:
	_ok(Iap.available(), "desktop debug: fake store open")
	Game.settings.erase("iap_noads")
	Game.settings.erase("iap_slots")
	Game.settings["iap_queue"] = []
	Game.hero = Hero.create("Thử Mua", "vo_dang")
	var h := Game.hero
	var j0 := int(h.jade)
	Iap.buy("ngoc_60")
	_ok(int(h.jade) == j0 + 120, "first Túi Ngọc gives double (120)")
	Iap.buy("ngoc_60")
	_ok(int(h.jade) == j0 + 180, "second Túi Ngọc gives 60")
	Iap.buy("ngoc_330")
	_ok(int(h.jade) == j0 + 180 + 660, "first Hộp Ngọc gives (300+30)×2")
	var g0 := int(h.gold)
	Iap.buy(Iap.STARTER)
	_ok(h.get("starter", false) and int(h.gold) == g0 + int(Iap.STARTER_GIFT.gold), "Gói Tân Thủ delivered")
	var j1 := int(h.jade)
	Iap.buy(Iap.STARTER)
	_ok(int(h.jade) == j1, "Gói Tân Thủ only once per hero")
	_ok(not Iap.no_ads(), "ads on before Bỏ QC")
	Iap.buy(Iap.NO_ADS)
	_ok(Iap.no_ads() and Ads.is_ready(), "Bỏ QC owned, rewarded counts as ready")
	var got := [false]
	Ads.show_rewarded(func(): got[0] = true)
	_ok(got[0], "Bỏ QC: rewarded offer granted without an ad")
	Iap.buy(Iap.SLOTS)
	_ok(Game.slot_open(4) and Game.slot_open(5), "ô 5–6 opened")
	# a pack bought with no hero open waits for the next hero
	Game.hero = {}
	Iap.buy("ngoc_700")
	_ok(Array(Game.settings.get("iap_queue", [])).has("ngoc_700"), "pack with no hero is queued")
	Game.hero = Hero.create("Người Sau", "nga_mi")
	var j2 := int(Game.hero.jade)
	Iap.deliver_queue()
	_ok(int(Game.hero.jade) == j2 + 1400 and Array(Game.settings.iap_queue).is_empty(), "queued pack delivered (first ×2: 1400)")

func _ach() -> void:
	var h := Hero.create("Thành Tựu", "thieu_lam")
	Hero.add_exp(h, 20000)
	_ok(Achieve.ready(h, "level"), "level tier ready after levelling (lv %d)" % int(h.level))
	h.stars[Journey.stage_id(0, 5)] = 3
	h.stars[Journey.stage_id(1, 5)] = 1
	_ok(Achieve.value(h, "region") == 2, "two region bosses counted")
	var j := int(h.jade)
	var rw := Achieve.claim(h, "region")
	_ok(not rw.is_empty() and int(h.jade) == j + int(rw.jade), "region tier 1 claimed")
	_ok(Achieve.ready(h, "region"), "region tier 2 still ready")
	Achieve.claim(h, "region")
	_ok(not Achieve.ready(h, "region") and Achieve.claim(h, "region").is_empty(), "no claim past the value")
	for i in 5:
		Daily.on_fight(h, "duel", {"won": true, "perfect": true, "ults": 3, "max_combo": 9})
	_ok(Achieve.value(h, "duel") == 5 and Achieve.value(h, "perfect") == 5 and Achieve.value(h, "combo") == 9 and Achieve.value(h, "ults") == 15, "fight counters")
	Daily.on_fight(h, "train", {"won": true, "perfect": true, "ults": 3, "max_combo": 30})
	_ok(Achieve.value(h, "combo") == 9, "training fights do not count")
	h.gear.weapon.plus = 10
	_ok(Achieve.value(h, "forge") == 10, "best + read from gear")
	_ok(Achieve.text("dungeon", 1).contains(Dungeon.DIFFS[1][0]), "dungeon tier named")
	var all := 0
	for id in Achieve.LINES:
		for k in Achieve.tiers(id).size():
			all += int(Achieve.reward(id, k).jade)
	print("     all tiers pay %d Ngọc" % all)
	_ok(all > 500 and all < 2500, "total achievement Ngọc in range")

func _funnel() -> void:
	var h := Hero.create("Phễu", "cai_bang")
	_ok(Funnel.reached(h) == ["f_hero"], "new hero: only f_hero")
	h.fights = 12
	h.wins = 7
	Hero.add_exp(h, 3000)
	h.stars[Journey.stage_id(0, 0)] = 2
	h.stars[Journey.stage_id(0, 5)] = 1
	h.created = Time.get_unix_time_from_system() - 3 * 86400
	var r := Funnel.reached(h)
	_ok(r.has("f_fight10") and r.has("f_win1") and r.has("f_r1s1") and r.has("f_r1s6") and not r.has("f_r1s3"), "fight / stage steps")
	_ok(r.has("f_day3") and not r.has("f_day7"), "day steps (%s)" % str(r.filter(func(s): return s.begins_with("f_day"))))
	_ok(r.has("f_lv5"), "level steps")
	_ok(Funnel._clean("p_Ngọc-60") == "p_ng_c_60", "event names cleaned")
