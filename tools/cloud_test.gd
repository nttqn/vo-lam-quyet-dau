extends Node
## Live cloud-save test against the real Firebase project in cloud_config.json.
##   godot --headless --path . -- --cloudtest
## Works in a throwaway guest account and a scratch user dir state:
## guest sign-up, upload, list, conflict detection, keep-local, delete.

func _ready() -> void:
	_run.call_deferred()

func _ok(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what + ("" if cond else "  last_error=" + Cloud.last_error))

func _run() -> void:
	print("cloud enabled=", Cloud.enabled())
	if not Cloud.enabled():
		get_tree().quit()
		return
	Cloud.sign_out()                       # fresh guest for the test
	var keep := Game.slot_info(2)          # park the dev machine's slot 2
	var fake := {"name": "Cloud Test", "sect": "vo_dang", "level": 7, "saved_at": 1000.0, "gold": 1}
	Game.write_slot(2, fake)
	var msg: String = await Cloud.sync_all()
	print("sync: ", msg, "  uid=", Cloud.uid)
	_ok(Cloud.uid != "", "guest sign-up")
	_ok(str(Cloud._ut.get("2", "")) != "", "slot 2 uploaded")
	# simulate another device writing the slot: our updateTime becomes stale
	Cloud._ut["2"] = "2001-01-01T00:00:00Z"
	fake.saved_at = 2000.0
	Game.write_slot(2, fake)
	var up: bool = await Cloud._upload(2)
	_ok(not up and Cloud.conflicts.has(2), "stale write rejected -> conflict")
	_ok(await Cloud.resolve_keep_local(2), "keep local overwrites cloud")
	Cloud.conflicts = {}
	var msg2: String = await Cloud.sync_all()
	_ok(Cloud.conflicts.is_empty(), "second sync clean (" + msg2 + ")")
	await Cloud.delete_slot(2)
	var r: Dictionary = await Cloud._req(HTTPClient.METHOD_GET, Cloud._doc_url(2), "", true)
	_ok(r.code == 404, "delete removed the document (HTTP %d)" % r.code)
	# email link -> sign out -> sign in again keeps the same uid
	var guest := Cloud.uid
	var mail := "cloudtest%d@example.com" % (Time.get_ticks_usec() % 100000000)
	_ok(await Cloud.link_email(mail, "test-pass-123"), "link guest to " + mail)
	_ok(Cloud.uid == guest, "link keeps uid")
	Cloud.sign_out()
	_ok(not await Cloud.sign_in_email(mail, "wrong-pass"), "wrong password rejected (" + Cloud.last_error + ")")
	_ok(await Cloud.sign_in_email(mail, "test-pass-123"), "sign in with email")
	_ok(Cloud.uid == guest, "sign in returns the same uid")
	# clean up: remove every test document and the test account
	for i in Game.SLOTS:
		await Cloud._req(HTTPClient.METHOD_DELETE, Cloud._doc_url(i), "", true)
	await Cloud._ensure_token()
	var d: Dictionary = await Cloud._req(HTTPClient.METHOD_POST, Cloud._auth_url("accounts:delete"), JSON.stringify({"idToken": Cloud._id_token}))
	_ok(d.code == 200, "test account deleted")
	# restore the dev slot
	if keep.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH % 2))
	else:
		Game.write_slot(2, keep)
	Cloud.sign_out()
	get_tree().quit()
