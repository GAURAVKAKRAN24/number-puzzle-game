class_name TestSceneIntegrity
extends RefCounted

static func run_all() -> int:
	var failed: int = 0
	var scenes_to_test: Array[String] = [
		"res://scenes/splash.tscn",
		"res://scenes/main_menu.tscn",
		"res://scenes/settings.tscn",
		"res://scenes/game.tscn",
		"res://scenes/components/tile.tscn",
		"res://scenes/components/board_cell.tscn",
		"res://scenes/components/pause_dialog.tscn",
		"res://scenes/components/confirmation_dialog.tscn",
		"res://scenes/components/how_to_play_dialog.tscn",
		"res://scenes/components/game_over_dialog.tscn"
	]
	
	for sc_path in scenes_to_test:
		if not ResourceLoader.exists(sc_path):
			printerr("FAIL: Scene file missing: ", sc_path)
			failed += 1
			continue
		
		var packed: PackedScene = load(sc_path)
		if not packed:
			printerr("FAIL: Failed to load PackedScene: ", sc_path)
			failed += 1
			continue
		
		var instance = packed.instantiate()
		if not instance:
			printerr("FAIL: Failed to instantiate scene: ", sc_path)
			failed += 1
			continue
		
		instance.queue_free()
		print("PASS: Scene integrity verified: ", sc_path)
	
	return failed
