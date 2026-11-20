extends Node
## Kênh Thế Giới checks:  godot --headless --path . -- --chattest
## Offline: text cleaning / censor / timestamps. Live (cloud_config set): a
## throwaway guest sends, is refused within the cooldown, reads it back,
## reports it, deletes it. The live part needs firestore.rules published.

var fails := 0

func _ready() -> void:
	_run.call_deferred()

func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + what + ("" if cond else "  last_error=%s raw=%s" % [Cloud.last_error, Cloud.last_raw.substr(0, 200)]))

func _run() -> void:
	_ok(Chat.clean("đm thua hoài") == "** thua hoài", "censor đm")
	_ok(Chat.clean("ĐỊTTT mẹ") == "***** mẹ", "censor repeated + caps: " + Chat.clean("ĐỊTTT mẹ"))
	_ok(Chat.clean("các bạn ơi lon bia buổi tối") == "các bạn ơi lon bia buổi tối", "everyday words untouched")
	_ok(Chat.clean("  fuck   you\n bro ") == "**** you bro", "whitespace folded: " + Chat.clean("  fuck   you\n bro "))
	_ok(Chat.clean("x".repeat(200)).length() == Chat.MAX_LEN, "length cap")
	_ok(Chat.clean("   ") == "", "blank -> empty")
	_ok(Chat.safe_name("bú lồn") == "bú ***", "name censor: " + Chat.safe_name("bú lồn"))
	var dec := "bu" + String.chr(0x301) + " lo" + String.chr(0x302) + String.chr(0x300) + "n"
	_ok(Chat.censor(dec) != dec, "decomposed lồn caught")
	var dec2 := "BÚ LÔ" + String.chr(0x300) + "N"
	_ok(Chat.censor(dec2) != dec2, "partly decomposed caps caught")
	var dd := "d" + String.chr(0x335) + "i" + String.chr(0x323) + "t"
	_ok(Chat.censor(dd) != dd, "d-stroke overlay caught")
	_ok(Chat.compose("Tiêu Dao Khách") == "tiêu dao khách", "compose leaves composed text")
	_ok(Chat.safe_name("Hỏa Long") == "Hỏa Long" and Chat.safe_name("chơi hèn") == "chơi hèn", "normal names untouched")
	var mh := Hero.migrate({"name": "bú lồn", "sect": "cai_bang", "rename_at": 999999999999})
	_ok(mh.name == "bú ***" and float(mh.rename_at) == 0.0, "migrate stars old name, frees rename: %s" % mh.name)
	if "--offline" in OS.get_cmdline_user_args():
		print("chattest done, fails=%d" % fails)
		get_tree().quit(1 if fails > 0 else 0)
		return
	_ok(absf(Chat.unix("2026-11-18T10:00:05.250Z") - Chat.unix("2026-11-18T10:00:05Z") - 0.25) < 0.001, "rfc3339 fraction")
	print("clock: ", Chat.clock("2026-11-18T10:00:05.250Z"))
	if Cloud.enabled():
		await _live()
	print("chattest done, fails=%d" % fails)
	get_tree().quit(1 if fails > 0 else 0)

func _live() -> void:
	var keep := Game.settings.duplicate(true)
	Cloud.sign_out()
	Game.hero = {"name": "Chat Test", "sect": "vo_dang", "level": 10}
	Game.settings["chat_last"] = 0.0
	var tag := "test %d" % (Time.get_ticks_usec() % 100000)
	var err: String = await Chat.send(tag)
	_ok(err == "", "send (%s)" % err)
	Game.settings["chat_last"] = 0.0   # skip the local wait: the server must refuse
	var err2: String = await Chat.send(tag + " again")
	_ok(err2.begins_with("Gửi quá nhanh"), "second send within 20 s refused by rules (%s)" % err2)
	var rows = await Chat.load_latest()
	var mine := {}
	if rows is Array:
		for m in rows:
			if str(m.text) == tag and str(m.uid) == Cloud.uid:
				mine = m
	_ok(not mine.is_empty(), "message read back")
	if not mine.is_empty():
		var later = await Chat.load_after(str(mine.at))
		_ok(later is Array and later.filter(func(m): return str(m._id) == str(mine._id)).is_empty(), "load_after excludes it")
		await Chat.report(mine)
		_ok(Cloud.last_error == "" or not Cloud.last_error.begins_with("HTTP 403"), "report accepted")
		_ok(await Chat.delete_msg(str(mine._id)), "delete own message")
	# a forged message (no chatlast in the same commit) must be refused
	var code: int = await Cloud.commit([{"path": "chat/forged%d" % randi(), "create": true, "server_time": ["at"],
		"fields": {"uid": Cloud.uid, "name": "x", "sect": "vo_dang", "level": 9, "text": "forged"}}])
	_ok(code == 403, "message without chatlast refused (HTTP %d)" % code)
	await Cloud.delete_account()
	Game.settings = keep
	Game.save_settings()
