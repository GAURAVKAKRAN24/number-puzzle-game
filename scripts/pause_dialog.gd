class_name PauseDialog
extends Control

signal resume_requested
signal restart_requested
signal how_to_play_requested
signal settings_requested
signal menu_requested

@onready var resume_btn: Button = $CenterContainer/Panel/VBox/ResumeBtn
@onready var restart_btn: Button = $CenterContainer/Panel/VBox/RestartBtn
@onready var how_to_play_btn: Button = $CenterContainer/Panel/VBox/HowToPlayBtn
@onready var menu_btn: Button = $CenterContainer/Panel/VBox/MenuBtn

func _ready() -> void:
	visible = false
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	how_to_play_btn.pressed.connect(_on_how_to_play)
	menu_btn.pressed.connect(_on_menu)

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func(): visible = false)

func _on_resume() -> void:
	_play_tap()
	close()
	resume_requested.emit()

func _on_restart() -> void:
	_play_tap()
	restart_requested.emit()

func _on_how_to_play() -> void:
	_play_tap()
	how_to_play_requested.emit()

func _on_menu() -> void:
	_play_tap()
	menu_requested.emit()

func _play_tap() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
