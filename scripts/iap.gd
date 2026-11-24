extends Node
## In-app purchases (autoload "Iap"):
## - Android: Google Play Billing through the GodotGooglePlayBilling plugin
##   (addons/GodotGooglePlayBilling, needs the gradle build).
## - iOS: StoreKit through the VLStoreKit GDExtension singleton
##   (ios_plugins/vl_storekit, built and added by the iOS CI only). Same product
##   ids in App Store Connect (store/iap-ios.md). Each transaction is granted
##   once (settings "iap_done", token "ios_<transaction id>") and then finished.
##   Non-consumables come back through Khôi phục giao dịch (Apple asks for the
##   Apple ID, so it is never run by itself on start).
## Desktop debug runs grant a purchase straight away, so the flows can be tested.
##
## Product ids, created in Play Console → Kiếm tiền → Sản phẩm trong ứng dụng:
##  - ngoc_60 / ngoc_330 / ngoc_700 / ngoc_1500: Ngọc packs (consumable). The
##    first buy of each pack per hero gives double (Quà nạp đầu).
##  - goi_tan_thu: starter pack (consumable), once per hero; the shop hides it after.
##  - bo_quang_cao: non-consumable. No interstitial / App Open, and rewarded
##    offers are given without the ad.
##  - mo_o_nhan_vat: non-consumable, opens save slots 5 and 6.
##
## Each purchase's Play signature is checked on the phone against
## LICENSE_KEY, so faked purchases (Lucky Patcher and the like) are refused.
## Each purchase token is granted once (settings "iap_done"), then consumed
## (consumables) or acknowledged (the others). Non-consumables are restored on
## every start from queryPurchases.
## Consumables that arrive with no hero open (a pending payment confirmed
## while on the title screen) wait in settings "iap_queue". The next hero to
## reach the hub gets them.

signal changed                       # prices / owned items changed (shop refresh)
signal message(text: String, ok: bool)

## Play Console → this app → Kiếm tiền → Thiết lập kiếm tiền → Cấp phép:
## the base64 RSA public key. Public by design. Empty = no signature check.
const LICENSE_KEY := "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm1Vajqb0uHONoykDQRhSlLIXU5/+SA5XMiOaG5CjgGyno/IslsN+TIFLOqGHfafMT2RvyUk+tlD09OycrEKS/pfaQCi6JKPpnq063qx4o//cdZ2/BwaUBS/ch7l5Xv1TM22vuWjQaOa/5HhGw0zto7MM/SNtL/oStXWuUBjEUJsJMu9NFeGoBIhfRnvTDQP6xJTHt03NNMm+TROW0oBKiDybZNlJh/xOSSghVG/1Ga37lOKAsjWxRt3xYdPqGdyfglo/ZakFFLj9YeS7eBQI3LE3FnHjJYQWXa1Mws+YiZEDv/sl2ccDrVwg6cj63zEURTgfuPNeiqLgs7PHqN3h3wIDAQAB"

const PACKS := {
	"ngoc_60": {"name": "Túi Ngọc", "jade": 60, "bonus": 0},
	"ngoc_330": {"name": "Hộp Ngọc", "jade": 300, "bonus": 30},
	"ngoc_700": {"name": "Rương Ngọc", "jade": 600, "bonus": 100},
	"ngoc_1500": {"name": "Bảo Khố Ngọc", "jade": 1200, "bonus": 300},
}
const STARTER := "goi_tan_thu"
const STARTER_GIFT := {"jade": 200, "gold": 6000, "mats": {"iron": 40, "charm": 3, "star": 3, "wash": 3}}
const NO_ADS := "bo_quang_cao"
const SLOTS := "mo_o_nhan_vat"
const SLOT_IDS := [4, 5]             # Game.SLOT_LEVEL -1 slots this opens
const NAMES := {STARTER: "Gói Tân Thủ", NO_ADS: "Bỏ Quảng Cáo", SLOTS: "Mở Ô Nhân Vật 5–6"}

const _PLUGIN := "GodotGooglePlayBilling"
const _SK := "VLStoreKit"
const _PURCHASED := 1
const _PENDING := 2

var prices := {}                     # sku -> formatted price from Play ("22.000 ₫")
var _bc: BillingClient
var _ready_store := false
var _busy_sku := ""
var _mode := ""                      # "play" | "apple" | "fake" | ""
var _sk: Object                      # VLStoreKit singleton (iOS)

func _ready() -> void:
	message.connect(_toast)
	if OS.get_name() == "Android" and Engine.has_singleton(_PLUGIN):
		_mode = "play"
		_bc = BillingClient.new()
		add_child(_bc)
		_bc.connected.connect(_on_connected)
		_bc.connect_error.connect(func(code: int, msg: String): print("Iap: connect error %d %s" % [code, msg]))
		_bc.query_product_details_response.connect(_on_details)
		_bc.query_purchases_response.connect(_on_owned)
		_bc.on_purchase_updated.connect(_on_updated)
		_bc.consume_purchase_response.connect(func(r: Dictionary): print("Iap: consume ", r.get("response_code")))
		_bc.acknowledge_purchase_response.connect(func(r: Dictionary): print("Iap: ack ", r.get("response_code")))
		_bc.start_connection()
	elif OS.get_name() == "iOS" and Engine.has_singleton(_SK):
		_mode = "apple"
		_sk = Engine.get_singleton(_SK)
		_sk.connect("event", _on_sk_event)
		_ready_store = _sk.can_pay()
		_sk.request_products(all_ids())
		_on_sk_event()   # transactions StoreKit replayed before we listened
	elif OS.is_debug_build() and not OS.get_name() in ["Android", "iOS"]:
		_mode = "fake"
		for id in all_ids():
			prices[id] = "%s ₫" % UI.fmt(_fake_price(id))

static func all_ids() -> PackedStringArray:
	var ids := PackedStringArray(PACKS.keys())
	ids.append_array([STARTER, NO_ADS, SLOTS])
	return ids

## Shop can sell (store connected, or the desktop test mode).
func available() -> bool:
	return _mode == "fake" or (_mode in ["play", "apple"] and _ready_store)

## Why the shop is closed, for the screen ("" when open).
func closed_reason() -> String:
	if OS.get_name() == "iOS":
		if _mode != "apple":
			return "Cửa hàng chưa mở trên máy này, hãy cập nhật bản mới nhất."
		if not _ready_store:
			return "Máy này đang tắt mua hàng trong ứng dụng (Cài đặt → Thời gian sử dụng → Giới hạn)."
		return ""
	if _mode == "play" and not _ready_store:
		return "Đang kết nối cửa hàng Google Play… Kiểm tra mạng và tài khoản Google."
	if _mode == "":
		return "Cửa hàng chỉ có trong bản tải từ Google Play."
	return ""

func price(id: String) -> String:
	return str(prices.get(id, ""))

func no_ads() -> bool:
	return bool(Game.settings.get("iap_noads", false))

func slots_owned() -> bool:
	return bool(Game.settings.get("iap_slots", false))

## Quà nạp đầu: this hero has not bought pack `id` yet (double Ngọc).
static func first_bonus(h: Dictionary, id: String) -> bool:
	return not id in h.get("topup", [])

static func pack_jade(h: Dictionary, id: String) -> int:
	var p: Dictionary = PACKS[id]
	var n := int(p.jade) + int(p.bonus)
	return n * 2 if first_bonus(h, id) else n

func buy(id: String) -> void:
	if _busy_sku != "":
		return
	if not available():
		message.emit(closed_reason(), false)
		return
	if id == STARTER and Game.hero.get("starter", false):
		return
	if _mode == "fake":
		_grant(id, "fake_%d" % Time.get_ticks_usec())
		return
	if not prices.has(id):
		message.emit("Gói này chưa có trên cửa hàng, hãy thử lại sau.", false)
		refresh_prices()
		return
	_busy_sku = id
	if _mode == "apple":
		_sk.purchase(id)
		return
	var r: Dictionary = _bc.purchase(id)
	if int(r.get("response_code", -99)) != BillingClient.BillingResponseCode.OK:
		_busy_sku = ""
		message.emit(_err_text(int(r.get("response_code", -99))), false)

## Settings → Khôi phục giao dịch: asks Play again for everything this
## account owns (Bỏ QC, ô nhân vật, or a pack left unfinished).
func restore() -> void:
	if _mode == "apple":
		if _restoring:
			return
		_restoring = true
		_had = [no_ads(), slots_owned()]
		_sk.restore()
		return
	if _mode != "play" or not _ready_store:
		message.emit(closed_reason() if closed_reason() != "" else "Không khôi phục được lúc này.", false)
		return
	_restoring = true
	_bc.query_purchases(BillingClient.ProductType.INAPP)

var _restoring := false
var _had := [false, false]           # iOS restore: [no_ads, slots] before it

## Gives queued consumables to the hero now playing (HubScreen calls this).
func deliver_queue() -> void:
	if Game.hero.is_empty():
		return
	var q: Array = Game.settings.get("iap_queue", [])
	if q.is_empty():
		return
	Game.settings["iap_queue"] = []
	Game.save_settings()
	for id in q:
		_give_hero(str(id))

# ------------------------------------------------------------- store callbacks
func _on_connected() -> void:
	_ready_store = true
	_bc.query_product_details(all_ids(), BillingClient.ProductType.INAPP)
	_bc.query_purchases(BillingClient.ProductType.INAPP)
	changed.emit()

## Why Play gave no price for an id (shown small in the shop): "mã N" from
## Billing's unfetched list (3 not found, 4 no eligible offer…), "no-offer"
## when the details came without a purchase option, "query N" on a failed query.
var missing := {}

## Ask Play again for whatever has no price yet (opening the shop).
func refresh_prices() -> void:
	if not _mode in ["play", "apple"] or not _ready_store:
		return
	for id in all_ids():
		if not prices.has(id):
			if _mode == "apple":
				_sk.request_products(all_ids())
			else:
				_bc.query_product_details(all_ids(), BillingClient.ProductType.INAPP)
			return

func _on_details(r: Dictionary) -> void:
	var code := int(r.get("response_code", -1))
	if code != 0:
		print("Iap: details ", r)
		for id in all_ids():
			if not prices.has(id):
				missing[id] = "query %d" % code
		changed.emit()
		return
	for d in r.get("product_details", []):
		var id := str(d.product_id)
		var offers = (d as Dictionary).get("one_time_purchase_offer_details_list")
		if offers is Array and not (offers as Array).is_empty():
			prices[id] = str((offers[0] as Dictionary).get("formatted_price", ""))
			missing.erase(id)
		else:
			missing[id] = "no-offer"
	for u in r.get("unfetched_products", []):
		if u is Dictionary:
			missing[str(u.get("product_id", "?"))] = "mã %d" % int(u.get("status_code", -1))
	if not missing.is_empty():
		print("Iap: no price for ", missing)
	changed.emit()

func _on_owned(r: Dictionary) -> void:
	var restoring := _restoring
	_restoring = false
	if int(r.get("response_code", -1)) != 0:
		if restoring:
			message.emit("Không khôi phục được (mã %d). Thử lại sau." % int(r.get("response_code", -1)), false)
		return
	var had_noads := no_ads()
	var had_slots := slots_owned()
	for p in r.get("purchases", []):
		_handle(p)
	if restoring:
		var got := []
		if no_ads() and not had_noads: got.append(NAMES[NO_ADS])
		if slots_owned() and not had_slots: got.append(NAMES[SLOTS])
		message.emit("Đã khôi phục: " + ", ".join(got) if not got.is_empty() else "Tài khoản Google Play này không có gói nào cần khôi phục.", true)
	changed.emit()

func _on_updated(r: Dictionary) -> void:
	var code := int(r.get("response_code", -1))
	_busy_sku = ""
	if code == BillingClient.BillingResponseCode.OK:
		for p in r.get("purchases", []):
			_handle(p)
	elif code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
		_bc.query_purchases(BillingClient.ProductType.INAPP)   # finish it / restore
	elif code != BillingClient.BillingResponseCode.USER_CANCELED:
		message.emit(_err_text(code), false)
	changed.emit()

func _handle(p: Dictionary) -> void:
	var state := int(p.get("purchase_state", 0))
	var ids: Array = Array(p.get("product_ids", []))
	if state == _PENDING:
		message.emit("Giao dịch đang chờ thanh toán. Quà sẽ vào khi Google Play xác nhận.", true)
		return
	if state != _PURCHASED:
		return
	var why := reject_reason(str(p.get("original_json", "")), str(p.get("signature", "")), ids)
	if why != "":
		print("Iap: refused (%s) %s" % [why, ids])
		Funnel.event("iap_bad_" + why)
		message.emit("Giao dịch không hợp lệ nên không được ghi nhận.", false)
		return
	var token := str(p.get("purchase_token", ""))
	for id in ids:
		_grant(str(id), token)
	if ids.size() == 1 and _consumable(str(ids[0])):
		_bc.consume_purchase(token)
	elif not bool(p.get("is_acknowledged", false)):
		_bc.acknowledge_purchase(token)

# ------------------------------------------------------------- StoreKit (iOS)
func _on_sk_event() -> void:
	if _sk == null:
		return
	for e in _sk.take_events():
		if e is Dictionary:
			_sk_one(e)
	changed.emit()

func _sk_one(e: Dictionary) -> void:
	var id := str(e.get("id", ""))
	match str(e.get("type", "")):
		"products":
			for it in e.get("items", []):
				prices[str(it.id)] = str(it.price)
				missing.erase(str(it.id))
			for bad in e.get("invalid", []):
				missing[str(bad)] = "invalid"
			if not missing.is_empty():
				print("Iap: no price for ", missing)
		"products_error":
			print("Iap: products error ", e.get("msg", ""))
			for i in all_ids():
				if not prices.has(i):
					missing[i] = "query"
		"purchased", "restored":
			_busy_sku = ""
			if id in all_ids():
				# a restore is not a new sale: keep it out of the purchase counters
				_grant(id, "ios_" + str(e.get("tid", "")), str(e.type) == "purchased")
			_sk.finish(str(e.get("tid", "")))
		"failed":
			_busy_sku = ""
			if not bool(e.get("cancelled", false)):
				message.emit("Mua không thành công (mã %d)." % int(e.get("code", -1)), false)
		"deferred":
			_busy_sku = ""
			message.emit("Giao dịch đang chờ phụ huynh duyệt. Quà sẽ vào khi được chấp thuận.", true)
		"restore_done":
			if _restoring:
				_restoring = false
				var got := []
				if no_ads() and not _had[0]: got.append(NAMES[NO_ADS])
				if slots_owned() and not _had[1]: got.append(NAMES[SLOTS])
				message.emit("Đã khôi phục: " + ", ".join(got) if not got.is_empty() else "Tài khoản Apple này không có gói nào cần khôi phục.", true)
		"restore_failed":
			_restoring = false
			message.emit("Không khôi phục được (mã %d). Thử lại sau." % int(e.get("code", -1)), false)

static func _consumable(id: String) -> bool:
	return PACKS.has(id) or id == STARTER

## Grants a purchase once per token. Non-consumables are flags, set again
## harmlessly on every restore.
func _grant(id: String, token: String, count := true) -> void:
	if id == NO_ADS:
		Game.settings["iap_noads"] = true
	elif id == SLOTS:
		Game.settings["iap_slots"] = true
		for i in SLOT_IDS:
			Game.settings["slot_open_%d" % i] = true
	var done: Array = Game.settings.get("iap_done", [])
	if token in done:
		Game.save_settings()
		return
	done.append(token)
	if done.size() > 200:
		done = done.slice(done.size() - 200)
	Game.settings["iap_done"] = done
	if count:
		Funnel.event("p_" + id)
	if _consumable(id):
		if Game.hero.is_empty():
			var q: Array = Game.settings.get("iap_queue", [])
			q.append(id)
			Game.settings["iap_queue"] = q
			Game.save_settings()
			message.emit("Đã mua %s. Quà sẽ vào nhân vật bạn chọn tiếp theo." % _name(id), true)
			return
		Game.save_settings()
		_give_hero(id)
		return
	Game.save_settings()
	message.emit("Đã mở " + _name(id) + "!", true)
	changed.emit()

func _give_hero(id: String) -> void:
	var h := Game.hero
	if PACKS.has(id):
		var n := pack_jade(h, id)
		var tu: Array = h.get("topup", [])
		if not id in tu:
			tu.append(id)
		h["topup"] = tu
		h.jade = int(h.jade) + n
		message.emit("Nhận %d Ngọc!" % n, true)
	elif id == STARTER:
		h["starter"] = true
		h.jade = int(h.jade) + int(STARTER_GIFT.jade)
		h.gold = int(h.gold) + int(STARTER_GIFT.gold)
		Mats.give(h, STARTER_GIFT.mats)
		message.emit("Đã nhận Gói Tân Thủ!", true)
	h["paid"] = int(h.get("paid", 0)) + 1
	Game.save()
	changed.emit()

## Purchase news can arrive on any screen (a pending payment confirmed later),
## so it is shown on its own top layer rather than by the shop.
var _layer: CanvasLayer

func _toast(text: String, ok: bool) -> void:
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.layer = 20
		add_child(_layer)
	var l := UI.label(text, 24, Color(0.6, 1, 0.7) if ok else Color(1, 0.72, 0.6), UI.bold)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	l.offset_left = -440
	l.offset_right = 440
	l.offset_top = 130
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "offset_top", 110.0, 0.25)
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	if ok:
		Game.sfx("coin")

static func _name(id: String) -> String:
	if PACKS.has(id):
		return PACKS[id].name
	return NAMES.get(id, id)

static func _err_text(code: int) -> String:
	match code:
		2, 12, -1, -3: return "Không kết nối được Google Play, hãy thử lại."
		3: return "Google Play trên máy này chưa sẵn sàng thanh toán."
		4: return "Gói này hiện không bán."
		7: return "Bạn đã sở hữu gói này. Đang khôi phục…"
	return "Mua không thành công (mã %d)." % code

static func _fake_price(id: String) -> int:
	return {"ngoc_60": 22000, "ngoc_330": 109000, "ngoc_700": 219000, "ngoc_1500": 449000,
		STARTER: 49000, NO_ADS: 69000, SLOTS: 49000}.get(id, 0)

# ------------------------------------------------------------- signature check
## Why a purchase is refused ("" = fine): "nosig" (no signature), "sku" (the
## signed data names another product), "sig" (not signed by Google). Nothing is
## refused while LICENSE_KEY is empty.
static func reject_reason(signed_json: String, signature: String, ids: Array, key_b64 := LICENSE_KEY) -> String:
	if key_b64.strip_edges() == "":
		return ""
	if signature.strip_edges() == "":
		return "nosig"
	var d = JSON.parse_string(signed_json)
	if not d is Dictionary:
		return "sig"
	var signed_ids := []
	if (d as Dictionary).has("productId"):
		signed_ids.append(str(d.productId))
	for x in (d as Dictionary).get("productIds", []):
		signed_ids.append(str(x))
	for id in ids:
		if not str(id) in signed_ids:
			return "sku"
	return "" if verify(signed_json, signature, key_b64) else "sig"

## RSASSA-PKCS1-v1_5 / SHA-1 check of Play's signature over the exact JSON text.
static func verify(data: String, signature_b64: String, key_b64: String) -> bool:
	var body := key_b64.strip_edges().replace("\n", "").replace(" ", "")
	var pem := "-----BEGIN PUBLIC KEY-----\n"
	for i in range(0, body.length(), 64):
		pem += body.substr(i, 64) + "\n"
	pem += "-----END PUBLIC KEY-----\n"
	var key := CryptoKey.new()
	if key.load_from_string(pem, true) != OK:
		return false
	var sig := Marshalls.base64_to_raw(signature_b64.strip_edges())
	if sig.is_empty():
		return false
	return Crypto.new().verify(HashingContext.HASH_SHA1, data.sha1_buffer(), sig, key)
