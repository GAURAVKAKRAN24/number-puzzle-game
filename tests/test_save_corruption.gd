class_name TestSaveCorruption
extends RefCounted

const SaveManagerRef = preload("res://scripts/autoload/save_manager.gd")

static func run_all() -> int:
	var failed: int = 0
	failed += test_valid_save_load()
	failed += test_corrupted_json_recovery()
	failed += test_invalid_schema_recovery()
	return failed

static func test_valid_save_load() -> int:
	var sm := SaveManagerRef.new()
	sm.reset_all_data()
	
	var board: Array = []
	for y in range(5):
		var row: Array = []
		for x in range(5):
			row.append(2 if (x == 0 and y == 0) else 0)
		board.append(row)
	
	var saved := sm.save_game(board, 250, 64)
	if not saved:
		printerr("FAIL: test_valid_save_load - save_game returned false")
		return 1
	
	var loaded := sm.load_game()
	if loaded.is_empty():
		printerr("FAIL: test_valid_save_load - loaded dictionary is empty")
		return 1
	if loaded.get("score") != 250:
		printerr("FAIL: test_valid_save_load - score mismatch: ", loaded.get("score"))
		return 1
	if loaded.get("best_score") != 250:
		printerr("FAIL: test_valid_save_load - best_score mismatch: ", loaded.get("best_score"))
		return 1
	if not sm.has_saved_game():
		printerr("FAIL: test_valid_save_load - has_saved_game returned false")
		return 1
	
	print("PASS: test_valid_save_load")
	return 0

static func test_corrupted_json_recovery() -> int:
	var sm := SaveManagerRef.new()
	sm.reset_all_data()
	
	# Manually write invalid/truncated JSON to save file
	var file := FileAccess.open(SaveManagerRef.SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("{ \"version\": 1, \"has_active_game\": true, \"board\": [ [2, 0, 0, 0, 0], TRUNCATED_CORRUPT_DATA!@#$")
		file.close()
	
	# load_game should not crash, must return empty and flag recovery
	var loaded := sm.load_game()
	if not loaded.is_empty():
		printerr("FAIL: test_corrupted_json_recovery - corrupt JSON should result in empty dictionary")
		return 1
	if not sm.last_corruption_recovered:
		printerr("FAIL: test_corrupted_json_recovery - corruption flag not set")
		return 1
	if sm.has_saved_game():
		printerr("FAIL: test_corrupted_json_recovery - active game should be false after corruption")
		return 1
	
	print("PASS: test_corrupted_json_recovery")
	return 0

static func test_invalid_schema_recovery() -> int:
	var sm := SaveManagerRef.new()
	sm.reset_all_data()
	
	# Write valid JSON but invalid board dimensions (e.g. only 3 rows instead of 5)
	var bad_data := {
		"version": 1,
		"has_active_game": true,
		"board": [[2, 0], [0, 4]], # Invalid dimensions
		"score": -100, # Invalid negative score
		"best_score": 50
	}
	var file := FileAccess.open(SaveManagerRef.SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(bad_data))
		file.close()
	
	var loaded := sm.load_game()
	if not loaded.is_empty():
		printerr("FAIL: test_invalid_schema_recovery - invalid schema should be rejected")
		return 1
	
	print("PASS: test_invalid_schema_recovery")
	return 0
