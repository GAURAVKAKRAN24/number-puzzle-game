class_name ScoreManager
extends RefCounted

signal score_changed(current_score: int, points_added: int)
signal new_best_score_reached(best_score: int)

var current_score: int = 0
var best_score: int = 0
var highest_tile_in_game: int = 2

func _init(initial_score: int = 0, initial_best: int = 0) -> void:
	current_score = maxi(0, initial_score)
	best_score = maxi(0, initial_best)

func calculate_points(result_value: int, chain_length: int) -> int:
	if result_value <= 0 or chain_length <= 0:
		return 0
	# Deterministic formula: Points = ResultValue * ChainLength
	return result_value * chain_length

func add_merge_score(result_value: int, chain_length: int) -> int:
	var points := calculate_points(result_value, chain_length)
	current_score += points
	
	if result_value > highest_tile_in_game:
		highest_tile_in_game = result_value
	
	score_changed.emit(current_score, points)
	
	if current_score > best_score:
		best_score = current_score
		new_best_score_reached.emit(best_score)
	
	return points

func reset(initial_best: int = 0) -> void:
	current_score = 0
	best_score = maxi(best_score, initial_best)
	highest_tile_in_game = 2
	score_changed.emit(0, 0)
