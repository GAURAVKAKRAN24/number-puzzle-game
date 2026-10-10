class_name MainMenu
extends Control

@onready var continue_btn: Button = %ContinueButton
@onready var play_btn: Button = %PlayButton
@onready var how_to_play_btn: Button = %HowToPlayButton
@onready var settings_btn: Button = %SettingsButton
@onready var privacy_btn: Button = %PrivacyButton
@onready var best_score_label: Label = %BestScoreLabel
@onready var how_to_play_dialog: HowToPlayDialog = %HowToPlayDialog
@onready var confirmation_dialog: ConfirmationDialogCustom = %ConfirmationDialog

func _ready() -> void:
	_update_ui()
	
	play_btn.pressed.connect(_on_play_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	privacy_btn.pressed.connect(_on_privacy_pressed)

func _update_ui() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var has_save := false
	var best := 0
	if sm:
		has_save = sm.has_saved_game()
		best = sm.get_best_score()
	
	continue_btn.visible = has_save
	best_score_label.text = str(best)

func _on_continue_pressed() -> void:
	_play_tap()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_play_pressed() -> void:
	_play_tap()
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_saved_game():
		confirmation_dialog.prompt(
			"Start New Game?",
			"You have a game in progress. Starting a new game will replace your current board.",
			"Start New"
		)
		confirmation_dialog.confirmed.connect(func():
			sm.clear_saved_game()
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		, CONNECT_ONE_SHOT)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_how_to_play_pressed() -> void:
	_play_tap()
	how_to_play_dialog.open()

func _on_settings_pressed() -> void:
	_play_tap()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_privacy_pressed() -> void:
	_play_tap()
	OS.shell_open("https://github.com/yourstudio/number-merge-puzzle/blob/main/docs/PRIVACY.md")

func _play_tap() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
