class_name GameOverDialog
extends Control

signal play_again_requested
signal home_requested
signal second_chance_requested

@onready var final_score_label: Label = $CenterContainer/Panel/VBox/ScoreContainer/FinalScore
@onready var best_score_label: Label = $CenterContainer/Panel/VBox/ScoreContainer/BestScore
@onready var play_again_btn: Button = $CenterContainer/Panel/VBox/PlayAgainBtn
@onready var home_btn: Button = $CenterContainer/Panel/VBox/HomeBtn
@onready var second_chance_btn: Button = $CenterContainer/Panel/VBox/SecondChanceBtn

var _second_chance_used: bool = false

func _ready() -> void:
	visible = false
	play_again_btn.pressed.connect(_on_play_again)
	home_btn.pressed.connect(_on_home)
	second_chance_btn.pressed.connect(_on_second_chance)

func open(final_score: int, best_score: int, can_offer_second_chance: bool = true) -> void:
	final_score_label.text = str(final_score)
	best_score_label.text = str(best_score)
	
	# Second chance can only be used once per run
	second_chance_btn.visible = can_offer_second_chance and not _second_chance_used
	
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func mark_second_chance_used() -> void:
	_second_chance_used = true
	second_chance_btn.visible = false

func reset_run() -> void:
	_second_chance_used = false

func close() -> void:
	visible = false

func _on_play_again() -> void:
	_play_tap()
	close()
	play_again_requested.emit()

func _on_home() -> void:
	_play_tap()
	close()
	home_requested.emit()

func _on_second_chance() -> void:
	_play_tap()
	second_chance_requested.emit()

func _play_tap() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()
