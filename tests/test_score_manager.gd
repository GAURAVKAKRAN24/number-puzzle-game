class_name TestScoreManager
extends RefCounted

const ScoreManagerRef = preload("res://scripts/score_manager.gd")

static func run_all() -> int:
	var failed: int = 0
	failed += test_point_calculations()
	failed += test_high_score_tracking()
	failed += test_score_reset()
	return failed

static func test_point_calculations() -> int:
	var sm = ScoreManagerRef.new(0, 100)
	
	# Formula: ResultValue * ChainLength
	# Example: 2 tiles merging to 4 -> 4 * 2 = 8 points
	var pts := sm.add_merge_score(4, 2)
	if pts != 8:
		printerr("FAIL: test_point_calculations - expected 8, got ", pts)
		return 1
	if sm.current_score != 8:
		printerr("FAIL: test_point_calculations - current_score mismatch: ", sm.current_score)
		return 1
	
	# 3 tiles merging to 16 -> 16 * 3 = 48 points
	pts = sm.add_merge_score(16, 3)
	if pts != 48:
		printerr("FAIL: test_point_calculations - expected 48, got ", pts)
		return 1
	if sm.current_score != 56:
		printerr("FAIL: test_point_calculations - expected total 56, got ", sm.current_score)
		return 1
	
	print("PASS: test_point_calculations")
	return 0

static func test_high_score_tracking() -> int:
	var sm = ScoreManagerRef.new(0, 50)
	sm.add_merge_score(4, 2) # total = 8
	if sm.best_score != 50:
		printerr("FAIL: test_high_score_tracking - best_score should remain 50")
		return 1
	
	sm.add_merge_score(64, 2) # adds 128 -> total = 136
	if sm.best_score != 136:
		printerr("FAIL: test_high_score_tracking - best_score should update to 136, got ", sm.best_score)
		return 1
	
	print("PASS: test_high_score_tracking")
	return 0

static func test_score_reset() -> int:
	var sm = ScoreManagerRef.new(100, 200)
	sm.reset(200)
	if sm.current_score != 0:
		printerr("FAIL: test_score_reset - current_score not 0 after reset")
		return 1
	if sm.best_score != 200:
		printerr("FAIL: test_score_reset - best_score should be preserved after reset")
		return 1
	print("PASS: test_score_reset")
	return 0
