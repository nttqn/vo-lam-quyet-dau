extends Node
## Prints the reminder texts and delays for a new and a level-20 hero.
##   godot --headless --path . -- --notifycheck

func _ready() -> void:
	var a := Hero.create("Tiểu Phong", "vo_dang")
	var b := Hero.create("Lão Hiệp", "nga_mi")
	Hero.add_exp(b, 20000)
	for s in 6:
		b.stars[Journey.stage_id(0, s)] = 2
	for h in [a, b]:
		for i in 3:
			var m := Notify.message(h, i)
			print("lv%d #%d %s | %s" % [int(h.level), i, m.title, m.body])
	for d in [1, 3, 7]:
		print("19:00 +%dd in %.1f h" % [d, Notify.seconds_to(19, d) / 3600.0])
	var gift := Journey.starter_gift(0, 1)
	print("gift s2: ", gift, " ", Items.item_name(Items.drop(gift, 1, 1), Sects.get_sect("vo_dang").style))
	get_tree().quit()
