class_name AccountPanel
extends Control
## Modal cloud-account overlay: guest -> link email, sign in on another device,
## password reset, sign out.

var _v: VBoxContainer
var _email: LineEdit
var _pass: LineEdit
var _msg: Label

func _ready() -> void:
	add_to_group("modal")   # Android back closes it (Game._go_back)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UI.panel()
	c.add_child(p)
	_v = UI.vbox(12)
	_v.custom_minimum_size.x = 620
	p.add_child(_v)
	_build()

func _build() -> void:
	for ch in _v.get_children():
		ch.queue_free()
	_v.add_child(UI.heading("Tài Khoản", 46))
	if Cloud.email != "":
		_v.add_child(UI.label("Đã liên kết: " + Cloud.email, 22, UI.GOLD, UI.bold))
		var t := UI.label("Nhân vật được tự động lưu lên mây. Trên máy khác, chọn \"Đăng nhập\" bằng email này để chơi tiếp.", 19)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_v.add_child(t)
		_msg = UI.label("", 19, Color(1, 0.75, 0.6))
		_v.add_child(_msg)
		var h := UI.hbox(10)
		_v.add_child(h)
		h.add_child(_delete_button())
		h.add_child(UI.button("Đăng xuất", func():
			Cloud.sign_out()
			_build(), 20))
		var close := UI.gold_button("Đóng", queue_free, 24)
		close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(close)
		return
	var t := UI.label("Bạn đang chơi với tư cách Khách: nhân vật vẫn được lưu lên mây nhưng chỉ gắn với máy này. Liên kết email để giữ nhân vật khi đổi máy hoặc cài lại game.", 19)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(t)
	_email = _field("Email", false)
	_pass = _field("Mật khẩu (ít nhất 6 ký tự)", true)
	_msg = UI.label("", 19, Color(1, 0.75, 0.6))
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(_msg)
	var h := UI.hbox(10)
	_v.add_child(h)
	var link := UI.gold_button("Liên kết email", _link, 22)
	link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(link)
	var login := UI.button("Đăng nhập", _login, 22)
	login.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(login)
	var h2 := UI.hbox(10)
	_v.add_child(h2)
	h2.add_child(UI.button("Quên mật khẩu", _reset, 18))
	h2.add_child(_delete_button())
	var close := UI.button("Đóng", queue_free, 20)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h2.add_child(close)

func _field(ph: String, secret: bool) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = ph
	e.secret = secret
	e.custom_minimum_size = Vector2(0, 54)
	e.add_theme_font_size_override("font_size", 22)
	if not secret:
		e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	_v.add_child(e)
	return e

func _inputs_ok(need_pass := true) -> bool:
	if not _email.text.strip_edges().contains("@"):
		_say("Hãy nhập email")
		return false
	if need_pass and _pass.text.length() < 6:
		_say("Mật khẩu cần ít nhất 6 ký tự")
		return false
	return true

func _say(t: String, col := Color(1, 0.75, 0.6)) -> void:
	_msg.text = t
	_msg.add_theme_color_override("font_color", col)

func _link() -> void:
	if not _inputs_ok():
		return
	_say("Đang liên kết…", UI.PAPER)
	if await Cloud.link_email(_email.text.strip_edges(), _pass.text):
		Game.sfx("coin")
		_build()
		_say("Đã liên kết. Nhân vật giờ gắn với email này.", Color(0.6, 1, 0.6))
	else:
		_say(Cloud.last_error)

func _login() -> void:
	if not _inputs_ok():
		return
	_say("Đang đăng nhập…", UI.PAPER)
	if await Cloud.sign_in_email(_email.text.strip_edges(), _pass.text):
		Game.sfx("coin")
		queue_free()
	else:
		_say(Cloud.last_error)

func _reset() -> void:
	if not _inputs_ok(false):
		return
	if await Cloud.reset_password(_email.text.strip_edges()):
		_say("Đã gửi thư đặt lại mật khẩu, hãy kiểm tra hộp thư.", Color(0.6, 1, 0.6))
	else:
		_say(Cloud.last_error)

## Two taps: the first arms it, the second deletes for good.
func _delete_button() -> Button:
	var b := UI.button("Xóa tài khoản", func(): pass, 16)
	b.add_theme_color_override("font_color", Color(1, 0.6, 0.55))
	b.pressed.connect(func():
		if not b.has_meta("armed"):
			b.set_meta("armed", true)
			b.text = "Bấm lần nữa để xóa vĩnh viễn"
			_say("Sẽ xóa tài khoản, mọi bản lưu trên mây và bóng Tỉ Võ. Nhân vật trong máy vẫn còn.")
			return
		_say("Đang xóa…", UI.PAPER)
		if await Cloud.delete_account():
			_build()
			_say("Đã xóa tài khoản và dữ liệu trên mây.", Color(0.6, 1, 0.6))
		else:
			_say(Cloud.last_error))
	return b
