extends SceneTree

const TestGridLogic = preload("res://tests/test_grid_logic.gd")
const TestScoreManager = preload("res://tests/test_score_manager.gd")
const TestSaveCorruption = preload("res://tests/test_save_corruption.gd")
const TestAdManager = preload("res://tests/test_ad_manager.gd")

const TestSceneIntegrity = preload("res://tests/test_scene_integrity.gd")

func _init() -> void:
	print("\n==========================================")
	print("   NUMBER MERGE PUZZLE - TEST SUITE")
	print("==========================================\n")
	
	var total_failed: int = 0
	
	print("--- Running Scene Integrity Tests ---")
	total_failed += TestSceneIntegrity.run_all()
	
	print("\n--- Running Grid Logic Tests ---")
	total_failed += TestGridLogic.run_all()
	
	print("\n--- Running Score Manager Tests ---")
	total_failed += TestScoreManager.run_all()
	
	print("\n--- Running Save Corruption & Schema Tests ---")
	total_failed += TestSaveCorruption.run_all()
	
	print("\n--- Running AdManager Tests ---")
	total_failed += TestAdManager.run_all()
	
	print("\n==========================================")
	if total_failed == 0:
		print("   ALL TESTS PASSED SUCCESSFULLY! (0 failures)")
		print("==========================================\n")
		quit(0)
	else:
		printerr("   TEST SUITE FAILED with ", total_failed, " failures!")
		print("==========================================\n")
		quit(1)
