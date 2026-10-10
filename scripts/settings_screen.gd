class_name SettingsScreen
extends Control

@onready var sound_check: CheckButton = %SoundCheck
@onready var vibration_check: CheckButton = %VibrationCheck
@onready var music_check: CheckButton = %MusicCheck
@onready var reset_data_btn: Button = %ResetDataBtn
@onready var privacy_btn: Button = %PrivacyBtn
@onready var back_btn: Button = %BackButton
@onready var confirmation_dialog: ConfirmationDialogCustom = %ConfirmationDialog

func _ready() -> void:
	_load_current_values()
	
	sound_check.toggled.connect(_on_sound_toggled)
	vibration_check.toggled.connect(_on_vibration_toggled)
	music_check.toggled.connect(_on_music_toggled)
	reset_data_btn.pressed.connect(_on_reset_pressed)
	privacy_btn.pressed.connect(_on_privacy_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	confirmation_dialog.confirmed.connect(_perform_reset_data)

func _load_current_values() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sound_check.set_pressed_no_signal(sm.sound_enabled)
		vibration_check.set_pressed_no_signal(sm.vibration_enabled)
		music_check.set_pressed_no_signal(sm.music_enabled)

func _on_sound_toggled(toggled: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("set_sound"):
		sm.set_sound(toggled)
	_play_tap()

func _on_vibration_toggled(toggled: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("set_vibration"):
		sm.set_vibration(toggled)
		if toggled:
			sm.vibrate(40)

func _on_music_toggled(toggled: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("set_music"):
		sm.set_music(toggled)
	_play_tap()

func _on_reset_pressed() -> void:
	_play_tap()
	confirmation_dialog.prompt(
		"Reset Game Data?",
		"This will delete your high score, best milestones, and any saved board progress. This cannot be undone.",
		"Delete All Data"
	)

func _perform_reset_data() -> void:
	var save_m = get_node_or_null("/root/SaveManager")
	if save_m and save_m.has_method("reset_all_data"):
		save_m.reset_all_data()

func _on_privacy_pressed() -> void:
	_play_tap()
	# Open privacy policy URL or documentation
	OS.shell_open("https://github.com/yourstudio/number-merge-puzzle/blob/main/docs/PRIVACY.md")

func _on_back_pressed() -> void:
	_play_tap()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _play_tap() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
