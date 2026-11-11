class_name Story
extends RefCounted
## Story lines of the Hành Tẩu Giang Hồ journey: one arc across the 7 regions
## (the Hắc Nguyệt Thần Giáo plot). Per region: "intro" when first entering,
## "boss" before the boss duel, "after" when the boss falls the first time.
## Speakers: "" = narrator, "@" = the hero (their name is shown), "boss" = the
## region boss, anything else is shown as written.
## h.story = [keys already seen], e.g. "2_boss".

const LINES := [
	{   # 0 Thiếu Thất Sơn Cước
		"intro": [
			["", "Mười năm khổ luyện nơi sư môn, nay là ngày xuống núi hành hiệp."],
			["", "Dân làng dưới chân Thiếu Thất kể rằng trại Hắc Phong dạo này cướp bóc dữ dội hơn hẳn, như có kẻ đứng sau tiếp sức."],
			["@", "Giang hồ hiểm ác, cứ từng bước mà đi."],
		],
		"boss": [
			["boss", "Thằng nhãi ranh dám phá trại của ta! Có biết ai chống lưng cho Hắc Phong trại không?"],
			["@", "Kẻ đứng sau ngươi là ai, đánh xong ngươi sẽ tự nói."],
			["boss", "Ha! Để xem ngươi đỡ nổi mấy chưởng!"],
		],
		"after": [
			["boss", "Khụ... Ta chỉ nhận vàng... Một kẻ áo đen đeo trăng khuyết bạc... hắn bảo ta gây loạn để dụ người các môn phái xuống núi..."],
			["@", "Trăng khuyết bạc? Phải tìm cho ra."],
			["", "Manh mối duy nhất: kẻ áo đen đã đi về phía rừng trúc phía tây."],
		],
	},
	{   # 1 Trúc Lâm Thâm Xứ
		"intro": [
			["", "Rừng trúc tây sơn mờ sương. Người ta đồn ở đây có một lão nhân thổi tiêu, biết hết chuyện giang hồ."],
			["@", "Nếu lão biết về kẻ đeo trăng khuyết, ta phải gặp lão."],
		],
		"boss": [
			["boss", "Tiếng chân ngươi gấp gáp, lòng ngươi còn gấp hơn. Người trẻ bây giờ ai cũng vậy."],
			["@", "Vãn bối muốn hỏi về kẻ áo đen đeo trăng khuyết bạc."],
			["boss", "Muốn hỏi thì phải để lão thử xem ngươi có đủ sức nghe câu trả lời không."],
		],
		"after": [
			["boss", "Kiếm ý không tệ. Trăng khuyết bạc là ấn tín của Hắc Nguyệt Thần Giáo, tưởng đã diệt từ ba mươi năm trước."],
			["boss", "Chúng đang mua binh khí qua bến Trường Giang. Đi đi, nhưng nhớ: kẻ thù thật sự thường không mặc áo đen."],
		],
	},
	{   # 2 Trường Giang Độ Khẩu
		"intro": [
			["", "Bến Trường Giang tấp nập thuyền buôn. Ban đêm, có những chiếc thuyền không treo đèn cập bến."],
			["@", "Hàng của Ma giáo hẳn đi qua đây."],
		],
		"boss": [
			["boss", "Thủy trại ta làm ăn đàng hoàng, ai trả tiền thì chở hàng. Ngươi muốn phá chén cơm của ta?"],
			["@", "Hàng ngươi chở là binh khí cho Hắc Nguyệt Thần Giáo."],
			["boss", "Biết nhiều thì chết sớm! Xuống sông làm mồi cho cá đi!"],
		],
		"after": [
			["boss", "Được... được rồi! Hàng chuyển lên Thiên Sơn, giao cho một nữ nhân... bọn ta gọi là Thánh Mẫu."],
			["", "Trong khoang thuyền là hàng trăm bộ giáp khắc trăng khuyết. Âm mưu này lớn hơn bạn tưởng."],
		],
	},
	{   # 3 Thiên Sơn Tuyết Lĩnh
		"intro": [
			["", "Thiên Sơn giá buốt. Tuyết rơi không ngừng, che kín dấu chân của những đoàn người lạ lên núi."],
			["@", "Lạnh thấu xương... nhưng không lạnh bằng lòng người."],
		],
		"boss": [
			["boss", "Ngươi lặn lội lên tận đây chỉ để chết trong tuyết sao?"],
			["@", "Bà nhận giáp của Ma giáo. Bà cũng là người của chúng?"],
			["boss", "Ta chỉ muốn Thiên Sơn được yên. Giáo chủ hứa sẽ để núi tuyết này ngoài cuộc chiến... nếu ta giữ chân kẻ như ngươi."],
		],
		"after": [
			["boss", "Ta sai rồi... Không ai đứng ngoài được cả. Đại quân của giáo đang tập kết ở cô thành giữa đại mạc."],
			["boss", "Cầm lấy tấm bản đồ này. Mong ngươi đến kịp."],
		],
	},
	{   # 4 Đại Mạc Cô Thành
		"intro": [
			["", "Cát vàng cuồn cuộn. Giữa sa mạc, cô thành bỏ hoang nay đầy lửa trại và tiếng mài đao."],
			["@", "Quả là đại quân. Phải phá chỗ này trước khi chúng kéo vào Trung Nguyên."],
		],
		"boss": [
			["boss", "Một mình mà dám vào thành ta? Gan lớn đấy, để xem gan ngươi có cứng bằng đao ta!"],
			["@", "Đao của ngươi chém người vô tội đủ rồi."],
		],
		"after": [
			["boss", "Giáo chủ... sẽ không tha cho ngươi... Tổng đàn ở hẻm núi Hắc Nguyệt, phía bắc..."],
			["", "Đại quân tan rã. Con đường tới tổng đàn Ma giáo đã mở."],
		],
	},
	{   # 5 Ma Giáo Tổng Đàn
		"intro": [
			["", "Hẻm núi Hắc Nguyệt, lửa đỏ rực trời. Đây là tổng đàn của Hắc Nguyệt Thần Giáo."],
			["@", "Đi tới đây rồi, không còn đường lui."],
		],
		"boss": [
			["boss", "Ta đã theo dõi ngươi từ chân núi Thiếu Thất. Kẻ duy nhất đi được tới đây."],
			["@", "Vì sao ngươi muốn gây loạn khắp giang hồ?"],
			["boss", "Gây loạn? Ta chỉ đẩy nhanh điều tất yếu. Ngũ đại phái tranh nhau hư danh, đã đến lúc giang hồ có một chủ nhân."],
			["boss", "Nhưng ta cũng chỉ là quân cờ. Thắng ta đi, rồi lên Thiên Trụ Phong mà hỏi kẻ cầm cờ."],
		],
		"after": [
			["boss", "Ngươi mạnh thật... Người ra lệnh cho ta... đang chờ ngươi ở đại hội luận võ trên Thiên Trụ Phong."],
			["", "Ma giáo sụp đổ, nhưng câu hỏi lớn nhất vẫn chưa có lời đáp."],
		],
	},
	{   # 6 Thiên Trụ Phong Luận Võ
		"intro": [
			["", "Đỉnh Thiên Trụ, quần hùng tề tựu luận võ. Một trong số họ là kẻ đứng sau tất cả."],
			["@", "Phải thắng từng người, cho tới khi kẻ đó lộ mặt."],
		],
		"boss": [
			["boss", "Cuối cùng ngươi cũng tới. Ta là kẻ đã dựng lại Hắc Nguyệt Thần Giáo."],
			["@", "Vì sao? Người được tôn là Thiên Hạ Đệ Nhất cơ mà."],
			["boss", "Vì ba mươi năm không ai đủ sức thách đấu ta. Ta tạo ra loạn thế để tìm một đối thủ xứng tầm... và ta đã tìm được."],
			["boss", "Ra tay đi. Đừng để ta thất vọng."],
		],
		"after": [
			["boss", "Hay... hay lắm. Giang hồ từ nay là của các ngươi, những người trẻ."],
			["", "Âm mưu của Hắc Nguyệt Thần Giáo chấm dứt. Danh tiếng của bạn vang khắp thiên hạ."],
			["", "Nhưng giang hồ chưa bao giờ ngừng sóng gió. Tháp Thí Luyện và đài Tỉ Võ vẫn đang chờ bạn."],
		],
	},
]

static func has(r: int, part: String) -> bool:
	return r >= 0 and r < LINES.size() and LINES[r].has(part)

static func seen(h: Dictionary, r: int, part: String) -> bool:
	return "%d_%s" % [r, part] in h.get("story", [])

static func mark(h: Dictionary, r: int, part: String) -> void:
	var s: Array = h.get("story", [])
	var k := "%d_%s" % [r, part]
	if not k in s:
		s.append(k)
	h.story = s

static func lines(r: int, part: String) -> Array:
	return LINES[r][part] if has(r, part) else []
