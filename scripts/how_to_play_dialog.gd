class_name HowToPlayDialog
extends Control

signal closed

@onready var close_btn: Button = $CenterContainer/Panel/VBox/CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func _on_close() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
	visible = false
	closed.emit()
