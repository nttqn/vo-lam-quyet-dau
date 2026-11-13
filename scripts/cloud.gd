extends Node
## Cloud save (autoload "Cloud"): Firebase Auth + Firestore over REST.
##
## - First launch signs in anonymously; the player can link an email/password
##   to carry the hero to another device (same uid), or sign in to one.
## - Each save slot is one document players/{uid}/slots/{i}:
##     data (JSON string of the hero), saved_at, name, sect, level.
## - Writes use the document's last known updateTime as a precondition, so a
##   copy changed on another device is never silently overwritten: that slot is
##   marked as a conflict and the title screen asks which copy to keep.
## - Disabled (every call is a no-op) while res://cloud_config.json is empty.

signal changed   # auth state / slot status changed (UI refresh)

const CONFIG_PATH := "res://cloud_config.json"
const STATE_PATH := "user://cloud.json"
const UPLOAD_DELAY := 4.0

var api_key := ""
var project_id := ""
var uid := ""
var email := ""            # "" = anonymous (guest)
var busy := false
var last_error := ""
var last_raw := ""         # raw server error text (debug)
var conflicts := {}        # slot -> cloud doc summary (see _doc_summary)

var _refresh := ""
var _id_token := ""
var _token_exp := 0.0
var _ut := {}              # str(slot) -> updateTime last read/written by this device
var _dirty := {}           # slot -> true, waiting for upload
var _timer: Timer

func _ready() -> void:
	var cfg = _read_json(CONFIG_PATH)
	if cfg is Dictionary:
		api_key = str(cfg.get("api_key", ""))
		project_id = str(cfg.get("project_id", ""))
	# test hooks (--flowtest, --fighttest, …) must never touch real cloud saves
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not "--cloudtest" in args:
		api_key = ""
	var st = _read_json(STATE_PATH)
	if st is Dictionary:
		uid = str(st.get("uid", ""))
		email = str(st.get("email", ""))
		_refresh = str(st.get("refresh", ""))
		var u = st.get("ut", {})
		_ut = u if u is Dictionary else {}
		var d = st.get("dirty", [])
		if d is Array:
			for s in d:
				_dirty[int(s)] = true
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_flush)
	add_child(_timer)

func enabled() -> bool:
	return api_key != "" and project_id != ""

func signed_in() -> bool:
	return uid != "" and _refresh != ""

# ------------------------------------------------------------- public API
## Called by Game.save(): upload this slot a few seconds later (debounced).
func queue_upload(slot: int) -> void:
	if not enabled() or slot < 0:
		return
	_dirty[slot] = true
	_save_state()
	_timer.start(UPLOAD_DELAY)

## Title screen: sign in if needed, then reconcile every slot with the cloud.
## Returns a short status text.
func sync_all() -> String:
	if not enabled():
		return ""
	if busy:
		return "Đang đồng bộ…"
	busy = true
	var msg := await _sync_all()
	busy = false
	changed.emit()
	return msg

## Keep the local copy for a conflicting slot (overwrites the cloud copy).
func resolve_keep_local(slot: int) -> bool:
	var c: Dictionary = conflicts.get(slot, {})
	_ut[str(slot)] = c.get("ut", "")
	conflicts.erase(slot)
	var ok := await _upload(slot)
	changed.emit()
	return ok

## Take the cloud copy for a conflicting slot (local copy parked as .bak).
func resolve_take_cloud(slot: int) -> void:
	var c: Dictionary = conflicts.get(slot, {})
	if c.is_empty():
		return
	_take(slot, c)
	conflicts.erase(slot)
	changed.emit()

func delete_slot(slot: int) -> void:
	_dirty.erase(slot)
	conflicts.erase(slot)
	if not enabled() or not signed_in():
		_ut.erase(str(slot))
		_save_state()
		return
	if await _ensure_token():
		await _req(HTTPClient.METHOD_DELETE, _doc_url(slot), "", true)
	_ut.erase(str(slot))
	_save_state()

## Link the current (guest) account to email + password. Same uid, saves stay.
func link_email(p_email: String, password: String) -> bool:
	if not await _ensure_token():
		return false
	# linking = signUp with the guest idToken (what the SDK's linkWithCredential does);
	# accounts:update is refused while email enumeration protection is on
	var r := await _req(HTTPClient.METHOD_POST, _auth_url("accounts:signUp"),
		JSON.stringify({"idToken": _id_token, "email": p_email, "password": password, "returnSecureToken": true}))
	if r.code != 200:
		last_error = _auth_error(r.body)
		return false
	_take_tokens(r.body)
	email = p_email
	_save_state()
	changed.emit()
	return true

## Sign in to an existing account (e.g. on a new phone), then sync.
func sign_in_email(p_email: String, password: String) -> bool:
	var r := await _req(HTTPClient.METHOD_POST, _auth_url("accounts:signInWithPassword"),
		JSON.stringify({"email": p_email, "password": password, "returnSecureToken": true}))
	if r.code != 200:
		last_error = _auth_error(r.body)
		return false
	_switch_user(r.body)
	email = p_email
	_save_state()
	changed.emit()
	return true

func reset_password(p_email: String) -> bool:
	var r := await _req(HTTPClient.METHOD_POST, _auth_url("accounts:sendOobCode"),
		JSON.stringify({"requestType": "PASSWORD_RESET", "email": p_email}))
	if r.code != 200:
		last_error = _auth_error(r.body)
		return false
	return true

## Deletes everything this account has on the server (cloud saves, this
## season's Tỉ Võ shadow) and the account itself. Local saves stay on the phone.
## Play policy: account deletion must be available in the app.
func delete_account() -> bool:
	if not await _ensure_token():
		return false
	for i in Game.SLOTS:
		await _req(HTTPClient.METHOD_DELETE, _doc_url(i), "", true)
	await _req(HTTPClient.METHOD_DELETE, _base_url() + "%s/%s" % [Duel.collection(), uid], "", true)
	for i in Game.SLOTS:
		await _req(HTTPClient.METHOD_DELETE, _base_url() + "%s/%s_%d" % [Ranks.COLLECTION, uid, i], "", true)
	var r := await _req(HTTPClient.METHOD_POST, _auth_url("accounts:delete"), JSON.stringify({"idToken": _id_token}))
	if r.code != 200:
		last_error = _auth_error(r.body)
		return false
	_dirty = {}
	sign_out()
	return true

## Forget this account on this device. Local saves stay; the next sync signs in
## as a new guest and uploads them there.
func sign_out() -> void:
	uid = ""
	email = ""
	_refresh = ""
	_id_token = ""
	_ut = {}
	conflicts = {}
	_save_state()
	changed.emit()

# ------------------------------------------------------------- sync
func _sync_all() -> String:
	if not await _ensure_token():
		return "Không kết nối được máy chủ"
	var r := await _req(HTTPClient.METHOD_GET, _base_url() + "players/%s/slots?pageSize=10" % uid, "", true)
	if r.code != 200:
		last_error = "HTTP %d" % r.code
		return "Không đọc được dữ liệu trên mây"
	var cloud := {}
	for d in (r.body as Dictionary).get("documents", []):
		var s := _doc_summary(d)
		if s.slot >= 0:
			cloud[s.slot] = s
	var pulled := 0
	var pushed := 0
	conflicts = {}
	for i in Game.SLOTS:
		var local := Game.slot_info(i)
		var key := str(i)
		if not cloud.has(i):
			if not local.is_empty():
				_ut.erase(key)
				if await _upload(i):
					pushed += 1
			continue
		var c: Dictionary = cloud[i]
		if local.is_empty():
			_take(i, c)
			pulled += 1
		elif str(_ut.get(key, "")) == c.ut:
			# cloud unchanged since our last sync: push only if we have newer play
			if _dirty.has(i) or float(local.get("saved_at", 0)) > c.saved_at + 0.5:
				if await _upload(i):
					pushed += 1
		elif absf(float(local.get("saved_at", 0)) - c.saved_at) < 0.5:
			_ut[key] = c.ut   # identical save, just never linked on this device
		else:
			conflicts[i] = c
	_save_state()
	var parts := []
	if pulled > 0: parts.append("tải về %d" % pulled)
	if pushed > 0: parts.append("lưu lên %d" % pushed)
	if not conflicts.is_empty(): parts.append("%d ô cần chọn bản" % conflicts.size())
	return "Đã đồng bộ" + (" (" + ", ".join(parts) + ")" if not parts.is_empty() else "")

func _flush() -> void:
	if busy:
		_timer.start(UPLOAD_DELAY)
		return
	busy = true
	for s in _dirty.keys():
		if not conflicts.has(s):
			await _upload(s)
	busy = false
	changed.emit()

func _upload(slot: int) -> bool:
	var info := Game.slot_info(slot)
	if info.is_empty():
		_dirty.erase(slot)
		return true
	if not await _ensure_token():
		return false
	var key := str(slot)
	var pre := "currentDocument.exists=false"
	if str(_ut.get(key, "")) != "":
		pre = "currentDocument.updateTime=" + str(_ut[key]).uri_encode()
	var body := {"fields": {
		"data": {"stringValue": JSON.stringify(info)},
		"saved_at": {"doubleValue": float(info.get("saved_at", 0))},
		"name": {"stringValue": str(info.get("name", ""))},
		"sect": {"stringValue": str(info.get("sect", ""))},
		"level": {"integerValue": str(int(info.get("level", 1)))},
	}}
	var r := await _req(HTTPClient.METHOD_PATCH, _doc_url(slot) + "?" + pre, JSON.stringify(body), true)
	if r.code == 200:
		_ut[key] = str((r.body as Dictionary).get("updateTime", ""))
		_dirty.erase(slot)
		_save_state()
		return true
	# 400 FAILED_PRECONDITION = updateTime moved (another device wrote it),
	# 409 = exists although we expected none, 404 = deleted on another device
	if r.code == 409 or r.code == 404 or (r.code == 400 and JSON.stringify(r.body).contains("FAILED_PRECONDITION")):
		var g := await _req(HTTPClient.METHOD_GET, _doc_url(slot), "", true)
		if g.code == 200:
			conflicts[slot] = _doc_summary(g.body)
		else:
			_ut.erase(key)   # gone in the cloud: next upload recreates it
	last_error = "HTTP %d" % r.code
	_save_state()
	return false

func _take(slot: int, c: Dictionary) -> void:
	var d = JSON.parse_string(str(c.get("data", "")))
	if not d is Dictionary or (d as Dictionary).is_empty():
		return
	Game.park_slot(slot)
	Game.write_slot(slot, d)
	_ut[str(slot)] = c.ut
	_dirty.erase(slot)
	_save_state()

func _doc_summary(doc) -> Dictionary:
	var f: Dictionary = (doc as Dictionary).get("fields", {})
	var nm := str((doc as Dictionary).get("name", ""))
	var s := nm.get_slice("/", nm.get_slice_count("/") - 1)
	return {
		"slot": int(s) if s.is_valid_int() else -1,
		"ut": str((doc as Dictionary).get("updateTime", "")),
		"data": str(f.get("data", {}).get("stringValue", "")),
		"saved_at": float(f.get("saved_at", {}).get("doubleValue", f.get("saved_at", {}).get("integerValue", 0))),
		"name": str(f.get("name", {}).get("stringValue", "")),
		"sect": str(f.get("sect", {}).get("stringValue", "")),
		"level": int(f.get("level", {}).get("integerValue", 1)),
	}

# ------------------------------------------------------------- auth
func _ensure_token() -> bool:
	if not enabled():
		return false
	if _id_token != "" and Time.get_unix_time_from_system() < _token_exp - 60:
		return true
	if _refresh != "":
		var r := await _req(HTTPClient.METHOD_POST, "https://securetoken.googleapis.com/v1/token?key=" + api_key,
			"grant_type=refresh_token&refresh_token=" + _refresh.uri_encode(), false, true)
		if r.code == 200:
			var b: Dictionary = r.body
			_id_token = str(b.get("id_token", ""))
			_refresh = str(b.get("refresh_token", _refresh))
			_token_exp = Time.get_unix_time_from_system() + float(b.get("expires_in", 3600))
			uid = str(b.get("user_id", uid))
			_save_state()
			return true
		if r.code == 0:
			last_error = "offline"
			return false
		# refresh token revoked / account deleted: fall through to a new guest
		last_error = _auth_error(r.body)
		sign_out()
	var s := await _req(HTTPClient.METHOD_POST, _auth_url("accounts:signUp"), JSON.stringify({"returnSecureToken": true}))
	if s.code != 200:
		last_error = "offline" if s.code == 0 else _auth_error(s.body)
		return false
	_switch_user(s.body)
	email = ""
	_save_state()
	return true

func _take_tokens(b: Dictionary) -> void:
	_id_token = str(b.get("idToken", ""))
	_refresh = str(b.get("refreshToken", _refresh))
	_token_exp = Time.get_unix_time_from_system() + float(b.get("expiresIn", 3600))
	uid = str(b.get("localId", uid))

func _switch_user(b: Dictionary) -> void:
	var old := uid
	_take_tokens(b)
	if uid != old:
		_ut = {}   # updateTimes belong to the previous account's documents
		conflicts = {}
		for i in Game.SLOTS:
			if not Game.slot_info(i).is_empty():
				_dirty[i] = true

static func _auth_error(body) -> String:
	var m := ""
	if body is Dictionary:
		m = str((body as Dictionary).get("error", {}).get("message", ""))
	match m.get_slice(" ", 0):
		"EMAIL_EXISTS": return "Email này đã có tài khoản, hãy đăng nhập"
		"INVALID_EMAIL": return "Email không hợp lệ"
		"WEAK_PASSWORD": return "Mật khẩu cần ít nhất 6 ký tự"
		"EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS": return "Sai email hoặc mật khẩu"
		"TOO_MANY_ATTEMPTS_TRY_LATER": return "Thử quá nhiều lần, hãy đợi một lát"
		"USER_DISABLED": return "Tài khoản đã bị khóa"
		"CREDENTIAL_TOO_OLD_LOGIN_AGAIN", "TOKEN_EXPIRED": return "Phiên đăng nhập đã cũ, hãy thử lại"
		"OPERATION_NOT_ALLOWED", "ADMIN_ONLY_OPERATION", "CONFIGURATION_NOT_FOUND": return "Máy chủ chưa bật kiểu đăng nhập này"
	return "Lỗi máy chủ" + (" (" + m + ")" if m != "" else "")

# ------------------------------------------------------------- shared docs (Tỉ Võ)
## Writes collection/{uid} with plain fields (String/int/float values).
func put_my_doc(collection: String, fields: Dictionary) -> bool:
	return await put_doc(collection, "", fields)

## Writes collection/{uid + suffix} (e.g. "_0" for save slot 0).
func put_doc(collection: String, suffix: String, fields: Dictionary) -> bool:
	if not await _ensure_token():
		return false
	var f := {}
	for k in fields:
		f[k] = _fs_value(fields[k])
	var r := await _req(HTTPClient.METHOD_PATCH, _base_url() + "%s/%s%s" % [collection, uid, suffix], JSON.stringify({"fields": f}), true)
	if r.code != 200:
		last_error = "HTTP %d" % r.code
	return r.code == 200

func delete_doc(collection: String, suffix: String) -> void:
	if await _ensure_token():
		await _req(HTTPClient.METHOD_DELETE, _base_url() + "%s/%s%s" % [collection, uid, suffix], "", true)

## How many documents have `field` greater than v (rank = count + 1); -1 on error.
func count_above(collection: String, field: String, v) -> int:
	if not await _ensure_token():
		return -1
	var body := {"structuredAggregationQuery": {
		"structuredQuery": {"from": [{"collectionId": collection}],
			"where": {"fieldFilter": {"field": {"fieldPath": field}, "op": "GREATER_THAN", "value": _fs_value(v)}}},
		"aggregations": [{"alias": "n", "count": {}}]}}
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runAggregationQuery" % project_id
	var r := await _req(HTTPClient.METHOD_POST, url, JSON.stringify(body), true)
	if r.code != 200:
		return -1
	for row in r.get("list", []):
		var res = (row as Dictionary).get("result")
		if res is Dictionary:
			return int(_fs_plain(res.get("aggregateFields", {}).get("n", {})))
	return -1

## Documents of a collection ordered by `order_field` (descending), optionally
## with order_field between lo and hi. Returns plain dicts with "_id" = doc id.
func query(collection: String, order_field: String, limit: int, lo = null, hi = null) -> Array:
	if not await _ensure_token():
		return []
	var sq := {
		"from": [{"collectionId": collection}],
		"orderBy": [{"field": {"fieldPath": order_field}, "direction": "DESCENDING"}],
		"limit": limit,
	}
	var filters := []
	if lo != null:
		filters.append({"fieldFilter": {"field": {"fieldPath": order_field}, "op": "GREATER_THAN_OR_EQUAL", "value": _fs_value(lo)}})
	if hi != null:
		filters.append({"fieldFilter": {"field": {"fieldPath": order_field}, "op": "LESS_THAN_OR_EQUAL", "value": _fs_value(hi)}})
	if filters.size() == 1:
		sq["where"] = filters[0]
	elif filters.size() > 1:
		sq["where"] = {"compositeFilter": {"op": "AND", "filters": filters}}
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % project_id
	var r := await _req(HTTPClient.METHOD_POST, url, JSON.stringify({"structuredQuery": sq}), true)
	var out := []
	if r.code != 200:
		last_error = "HTTP %d" % r.code
		return out
	# runQuery answers with a JSON array; _req only keeps dictionaries
	for row in r.get("list", []):
		var d = (row as Dictionary).get("document")
		if d is Dictionary:
			var plain := {}
			var fl: Dictionary = d.get("fields", {})
			for k in fl:
				plain[k] = _fs_plain(fl[k])
			var nm := str(d.get("name", ""))
			plain["_id"] = nm.get_slice("/", nm.get_slice_count("/") - 1)
			out.append(plain)
	return out

static func _fs_value(v) -> Dictionary:
	match typeof(v):
		TYPE_INT: return {"integerValue": str(v)}
		TYPE_FLOAT: return {"doubleValue": v}
		TYPE_BOOL: return {"booleanValue": v}
		_: return {"stringValue": str(v)}

static func _fs_plain(v: Dictionary):
	if v.has("integerValue"): return int(v.integerValue)
	if v.has("doubleValue"): return float(v.doubleValue)
	if v.has("booleanValue"): return bool(v.booleanValue)
	return str(v.get("stringValue", ""))

# ------------------------------------------------------------- http
func _auth_url(method: String) -> String:
	return "https://identitytoolkit.googleapis.com/v1/%s?key=%s" % [method, api_key]

func _base_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/" % project_id

func _doc_url(slot: int) -> String:
	return _base_url() + "players/%s/slots/%d" % [uid, slot]

## Returns {code, body}; code 0 = no connection.
func _req(method: int, url: String, body := "", auth := false, form := false) -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = 15.0
	add_child(h)
	var headers := PackedStringArray(["Content-Type: " + ("application/x-www-form-urlencoded" if form else "application/json")])
	if auth:
		headers.append("Authorization: Bearer " + _id_token)
	var err := h.request(url, headers, method, body)
	if err != OK:
		h.queue_free()
		return {"code": 0, "body": {}}
	var res: Array = await h.request_completed
	h.queue_free()
	var code: int = res[1] if res[0] == HTTPRequest.RESULT_SUCCESS else 0
	var txt := (res[3] as PackedByteArray).get_string_from_utf8()
	if code >= 400:
		last_raw = txt.substr(0, 400)
	var parsed = JSON.parse_string(txt)
	return {"code": code, "body": parsed if parsed is Dictionary else {}, "list": parsed if parsed is Array else []}

# ------------------------------------------------------------- state file
func _save_state() -> void:
	var f := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"uid": uid, "email": email, "refresh": _refresh, "ut": _ut, "dirty": _dirty.keys()}))

static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f else null
