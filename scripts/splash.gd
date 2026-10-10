class_name SplashScreen
extends Control

@onready var title_label: Label = $Center/VBox/Title
@onready var subtitle_label: Label = $Center/VBox/Subtitle
@onready var icon_panel: Panel = $Center/VBox/IconBox/Panel

func _ready() -> void:
	modulate.a = 0.0
	
	# Fade in splash
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_go_to_menu)

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
