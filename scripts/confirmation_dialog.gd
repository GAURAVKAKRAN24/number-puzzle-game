class_name ConfirmationDialogCustom
extends Control

signal confirmed
signal cancelled

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var message_label: Label = $CenterContainer/Panel/VBox/MessageLabel
@onready var confirm_button: Button = $CenterContainer/Panel/VBox/HBox/ConfirmButton
@onready var cancel_button: Button = $CenterContainer/Panel/VBox/HBox/CancelButton

func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)

func prompt(title_text: String, msg_text: String, confirm_text: String = "Confirm") -> void:
	title_label.text = title_text
	message_label.text = msg_text
	confirm_button.text = confirm_text
	visible = true
	
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func _on_confirm() -> void:
	_play_tap()
	visible = false
	confirmed.emit()

func _on_cancel() -> void:
	_play_tap()
	visible = false
	cancelled.emit()

func _play_tap() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
