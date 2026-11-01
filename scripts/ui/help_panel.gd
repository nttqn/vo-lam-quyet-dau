class_name HelpPanel
extends Control
## How to play overlay.

const TEXT := """[b]Điều khiển[/b]
• Cần điều khiển bên trái: đi tới / lùi. Đẩy lên để nhảy, kéo xuống để ngồi.
• Giữ hướng [b]lùi[/b] để đỡ đòn. Ngồi + lùi để đỡ đòn thấp (quét chân).
• Đòn bổ từ trên cao và đòn trên không phải [b]đứng[/b] đỡ.
• [b]Quyền / Cước[/b]: bấm liên tục để ra liên hoàn chiêu.
• Tiến + Quyền/Cước: đòn lao tới.  Ngồi + Quyền: đòn thấp.  Ngồi + Cước: quét ngã.
• [b]Né[/b]: lùi né, có khoảnh khắc bất tử. Tiến + Né: lướt tới.
• Tiến + Né khi áp sát: [b]Cầm Nã[/b] — quật ngã, phá thế thủ.
• Ba ô [b]võ công[/b] tiêu hao Nội Lực (thanh xanh). Đánh trúng có thể nối thẳng sang võ công.

[b]Hành tẩu giang hồ[/b]
• 7 vùng đất, mỗi vùng 6 trận, trận cuối là trùm. Thắng 2 hiệp để qua trận.
• ★ thắng · ★★ còn từ 50% sinh lực · ★★★ thắng không mất hiệp nào.
• Lên cấp nhận điểm tiềm năng (Lực, Thân pháp, Nội công, Thể chất) và điểm võ công.
• Lôi Đài: đấu liên tiếp, đối thủ mạnh dần, phần thưởng tăng theo chuỗi thắng.
• Luyện Công: đánh mộc nhân để tập chiêu, không mất gì.

[b]Bàn phím (máy tính)[/b]: A/D đi, W nhảy, S ngồi, J quyền, K cước, L né, U/I/O võ công."""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UI.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 60
	p.offset_right = -60
	p.offset_top = 30
	p.offset_bottom = -30
	add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.heading("Hướng Dẫn", 44))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = TEXT
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 20)
	rt.add_theme_font_size_override("bold_font_size", 20)
	rt.add_theme_font_override("normal_font", UI.med)
	rt.add_theme_font_override("bold_font", UI.bold)
	rt.add_theme_color_override("default_color", UI.PAPER)
	v.add_child(rt)
	v.add_child(UI.gold_button("Đã hiểu", queue_free, 24))
