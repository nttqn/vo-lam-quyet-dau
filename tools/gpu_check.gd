extends SceneTree
## Checks Gfx.weak_gpu on known driver names: godot --headless -s tools/gpu_check.gd
func _init() -> void:
	var cases := {
		"PowerVR Rogue GE8320": true, "PowerVR Rogue GE8322": true, "IMG GE8322": true,
		"Mali-G52 MC2": true, "Mali-G52": true, "Mali-T830 MP1": true, "Mali-450 MP": true,
		"Mali-G57 MC2": false, "Mali-G68 MC4": false, "Mali-G520": false,
		"Adreno (TM) 506": true, "Adreno (TM) 610": true, "Adreno (TM) 618": true,
		"Adreno (TM) 619": true, "Adreno (TM) 642L": false, "Adreno (TM) 730": false,
	}
	var bad := 0
	for n in cases:
		var got := Gfx.weak_gpu_name(n)
		if got != cases[n]:
			bad += 1
			print("FAIL ", n, " got ", got)
	print("gpu_check: %d cases, %d bad" % [cases.size(), bad])
	quit(1 if bad else 0)
