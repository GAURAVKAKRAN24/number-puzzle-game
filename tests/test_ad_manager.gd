class_name TestAdManager
extends RefCounted

const AdManagerRef = preload("res://scripts/autoload/ad_manager.gd")

static func run_all() -> int:
	var failed: int = 0
	failed += test_admob_test_ids()
	failed += test_reward_double_callback_protection()
	failed += test_interstitial_frequency_capping()
	return failed

static func test_admob_test_ids() -> int:
	# Verify that Google AdMob official test IDs are set correctly
	if AdManagerRef.TEST_APP_ID != "ca-app-pub-3940256099942544~3347511713":
		printerr("FAIL: test_admob_test_ids - TEST_APP_ID incorrect")
		return 1
	if AdManagerRef.TEST_INTERSTITIAL_ID != "ca-app-pub-3940256099942544/1033173712":
		printerr("FAIL: test_admob_test_ids - TEST_INTERSTITIAL_ID incorrect")
		return 1
	if AdManagerRef.TEST_REWARDED_ID != "ca-app-pub-3940256099942544/5224354917":
		printerr("FAIL: test_admob_test_ids - TEST_REWARDED_ID incorrect")
		return 1
	print("PASS: test_admob_test_ids")
	return 0

static func test_reward_double_callback_protection() -> int:
	var adm := AdManagerRef.new()
	var reward_counter: Array[int] = [0]
	var callback := func(): reward_counter[0] += 1
	
	adm.is_rewarded_ready = true
	adm.show_rewarded_ad(callback)
	
	# Simulate multiple malicious or buggy SDK callbacks from one ad impression
	adm._grant_reward_safely("revive", 1)
	adm._grant_reward_safely("revive", 1) # Duplicate attempt
	adm._grant_reward_safely("revive", 1) # Duplicate attempt
	
	if reward_counter[0] != 1:
		printerr("FAIL: test_reward_double_callback_protection - expected 1 reward, got ", reward_counter[0])
		return 1
	
	print("PASS: test_reward_double_callback_protection")
	return 0

static func test_interstitial_frequency_capping() -> int:
	var adm := AdManagerRef.new()
	adm.is_interstitial_ready = true
	
	# First game over: should NOT trigger (game_over_count = 1, frequency = 3)
	var shown1 := adm.show_interstitial_on_game_over()
	if shown1:
		printerr("FAIL: test_interstitial_frequency_capping - interstitial shown too early (game over #1)")
		return 1
	
	adm.is_interstitial_ready = true
	var shown2 := adm.show_interstitial_on_game_over()
	if shown2:
		printerr("FAIL: test_interstitial_frequency_capping - interstitial shown too early (game over #2)")
		return 1
	
	adm.is_interstitial_ready = true
	var shown3 := adm.show_interstitial_on_game_over()
	if not shown3:
		printerr("FAIL: test_interstitial_frequency_capping - interstitial should show on game over #3")
		return 1
	
	# Immediate subsequent game over should be capped by time interval
	adm.is_interstitial_ready = true
	var shown_immediate := adm.show_interstitial_on_game_over()
	if shown_immediate:
		printerr("FAIL: test_interstitial_frequency_capping - immediate repeat interstitial must be capped by time")
		return 1
	
	print("PASS: test_interstitial_frequency_capping")
	return 0
