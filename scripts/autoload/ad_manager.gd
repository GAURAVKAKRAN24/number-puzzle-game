class_name AdManagerClass
extends Node

signal interstitial_loaded
signal interstitial_failed_to_load(error_code: int)
signal interstitial_dismissed
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error_code: int)
signal rewarded_ad_opened
signal rewarded_ad_closed
signal user_earned_reward(type: String, amount: int)

# Official Google AdMob Android Test Identifiers
const TEST_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
const TEST_BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

# Frequency Capping & Natural Break Controls
const MIN_INTERSTITIAL_INTERVAL_SEC: float = 90.0
const INTERSTITIAL_GAME_OVER_FREQUENCY: int = 3

var is_interstitial_ready: bool = false
var is_rewarded_ready: bool = false

var _reward_pending_grant: bool = false
var _reward_callback: Callable = Callable()
var _last_interstitial_timestamp: float = -9999.0
var _game_over_count: int = 0
var _admob_singleton: Object = null
var _is_real_sdk: bool = false

func _ready() -> void:
	_initialize_admob()

func _initialize_admob() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		_admob_singleton = Engine.get_singleton("PoingGodotAdMob")
		_is_real_sdk = true
		_setup_native_listeners()
	elif Engine.has_singleton("GodotAdMob"):
		_admob_singleton = Engine.get_singleton("GodotAdMob")
		_is_real_sdk = true
		_setup_native_listeners()
	else:
		_is_real_sdk = false
		print("[AdManager] Native AdMob plugin not active. Running in graceful Stub/Mock mode.")
		# In stub mode, simulate ads ready after brief background delay
		_simulate_stub_loads()

func _setup_native_listeners() -> void:
	if not _admob_singleton:
		return
	# Connect signals if singleton provides them
	if _admob_singleton.has_signal("on_interstitial_loaded"):
		_admob_singleton.connect("on_interstitial_loaded", _on_native_interstitial_loaded)
	if _admob_singleton.has_signal("on_interstitial_failed_to_load"):
		_admob_singleton.connect("on_interstitial_failed_to_load", _on_native_interstitial_failed)
	if _admob_singleton.has_signal("on_interstitial_closed"):
		_admob_singleton.connect("on_interstitial_closed", _on_native_interstitial_closed)
	
	if _admob_singleton.has_signal("on_rewarded_loaded"):
		_admob_singleton.connect("on_rewarded_loaded", _on_native_rewarded_loaded)
	if _admob_singleton.has_signal("on_rewarded_failed_to_load"):
		_admob_singleton.connect("on_rewarded_failed_to_load", _on_native_rewarded_failed)
	if _admob_singleton.has_signal("on_rewarded_user_earned_reward"):
		_admob_singleton.connect("on_rewarded_user_earned_reward", _on_native_reward_earned)
	if _admob_singleton.has_signal("on_rewarded_closed"):
		_admob_singleton.connect("on_rewarded_closed", _on_native_rewarded_closed)
	
	# Initial background preload
	preload_ads()

func preload_ads() -> void:
	if _is_real_sdk and _admob_singleton:
		if _admob_singleton.has_method("load_interstitial"):
			_admob_singleton.call("load_interstitial", TEST_INTERSTITIAL_ID)
		if _admob_singleton.has_method("load_rewarded"):
			_admob_singleton.call("load_rewarded", TEST_REWARDED_ID)
	else:
		_simulate_stub_loads()

func _simulate_stub_loads() -> void:
	if is_inside_tree():
		var timer := get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			is_interstitial_ready = true
			is_rewarded_ready = true
			interstitial_loaded.emit()
			rewarded_ad_loaded.emit()
		)
	else:
		is_interstitial_ready = true
		is_rewarded_ready = true

func is_rewarded_available() -> bool:
	return is_rewarded_ready

func show_interstitial_on_game_over() -> bool:
	_game_over_count += 1
	var current_time := Time.get_unix_time_from_system()
	var elapsed := current_time - _last_interstitial_timestamp
	
	# Frequency capping check
	if _game_over_count % INTERSTITIAL_GAME_OVER_FREQUENCY != 0:
		return false
	if elapsed < MIN_INTERSTITIAL_INTERVAL_SEC:
		return false
	if not is_interstitial_ready:
		return false
	
	_last_interstitial_timestamp = current_time
	is_interstitial_ready = false
	
	if _is_real_sdk and _admob_singleton and _admob_singleton.has_method("show_interstitial"):
		_admob_singleton.call("show_interstitial")
		return true
	else:
		print("[AdManager:Mock] Interstitial shown after game over break.")
		if is_inside_tree():
			var timer := get_tree().create_timer(0.5)
			timer.timeout.connect(func():
				interstitial_dismissed.emit()
				preload_ads()
			)
		else:
			interstitial_dismissed.emit()
		return true

func show_rewarded_ad(on_reward_callback: Callable) -> bool:
	if not is_rewarded_ready:
		push_warning("[AdManager] Rewarded ad not ready.")
		return false
	
	_reward_pending_grant = true
	_reward_callback = on_reward_callback
	is_rewarded_ready = false
	rewarded_ad_opened.emit()
	
	if _is_real_sdk and _admob_singleton and _admob_singleton.has_method("show_rewarded"):
		_admob_singleton.call("show_rewarded")
		return true
	else:
		print("[AdManager:Mock] Simulating rewarded ad playback...")
		if is_inside_tree():
			var timer := get_tree().create_timer(1.2)
			timer.timeout.connect(func():
				_grant_reward_safely("revive", 1)
				rewarded_ad_closed.emit()
				preload_ads()
			)
		else:
			_grant_reward_safely("revive", 1)
			rewarded_ad_closed.emit()
		return true

func _grant_reward_safely(type: String, amount: int) -> void:
	if _reward_pending_grant:
		_reward_pending_grant = false
		user_earned_reward.emit(type, amount)
		if _reward_callback.is_valid():
			_reward_callback.call()
			_reward_callback = Callable()

# Native AdMob Callbacks
func _on_native_interstitial_loaded() -> void:
	is_interstitial_ready = true
	interstitial_loaded.emit()

func _on_native_interstitial_failed(code: int) -> void:
	is_interstitial_ready = false
	interstitial_failed_to_load.emit(code)

func _on_native_interstitial_closed() -> void:
	interstitial_dismissed.emit()
	preload_ads()

func _on_native_rewarded_loaded() -> void:
	is_rewarded_ready = true
	rewarded_ad_loaded.emit()

func _on_native_rewarded_failed(code: int) -> void:
	is_rewarded_ready = false
	rewarded_ad_failed_to_load.emit(code)

func _on_native_reward_earned(type: String, amount: int) -> void:
	_grant_reward_safely(type, amount)

func _on_native_rewarded_closed() -> void:
	_reward_pending_grant = false
	rewarded_ad_closed.emit()
	preload_ads()
