class_name SaveManagerClass
extends Node

signal best_score_updated(new_best: int)
signal save_data_corrupted_recovered

const SAVE_FILE_PATH: String = "user://game_save.json"
const SAVE_TEMP_PATH: String = "user://game_save.tmp"
const CURRENT_SAVE_VERSION: int = 1
const GRID_SIZE: int = 5

var best_score: int = 0
var highest_tile_achieved: int = 2
var saved_game_available: bool = false
var last_corruption_recovered: bool = false

func _ready() -> void:
	load_persisted_metadata()

func get_best_score() -> int:
	return best_score

func get_highest_tile_achieved() -> int:
	return highest_tile_achieved

func has_saved_game() -> bool:
	return saved_game_available

func update_best_score(new_score: int) -> void:
	if new_score > best_score:
		best_score = new_score
		best_score_updated.emit(best_score)
		_save_metadata_only()

func update_highest_tile(val: int) -> void:
	if val > highest_tile_achieved:
		highest_tile_achieved = val
		_save_metadata_only()

func save_game(board: Array, score: int, highest_tile: int) -> bool:
	if score > best_score:
		best_score = score
		best_score_updated.emit(best_score)
	if highest_tile > highest_tile_achieved:
		highest_tile_achieved = highest_tile
	
	var data := {
		"version": CURRENT_SAVE_VERSION,
		"has_active_game": true,
		"board": board,
		"score": maxi(0, score),
		"best_score": best_score,
		"highest_tile": highest_tile_achieved,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var json_str := JSON.stringify(data, "\t")
	var success := _atomic_write(SAVE_FILE_PATH, json_str)
	if success:
		saved_game_available = true
	return success

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		_handle_corruption("Cannot open save file for reading")
		return {}
	
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		_handle_corruption("Save file JSON parse error: " + json.get_error_message())
		return {}
	
	var dict = json.data
	if typeof(dict) != TYPE_DICTIONARY:
		_handle_corruption("Save file root is not a dictionary")
		return {}
	
	# Validate schema
	if not _validate_save_dict(dict):
		_handle_corruption("Save file failed schema validation")
		return {}
	
	best_score = maxi(best_score, int(dict.get("best_score", 0)))
	highest_tile_achieved = maxi(highest_tile_achieved, int(dict.get("highest_tile", 2)))
	saved_game_available = bool(dict.get("has_active_game", false))
	
	return dict

func clear_saved_game() -> void:
	saved_game_available = false
	var data := {
		"version": CURRENT_SAVE_VERSION,
		"has_active_game": false,
		"board": [],
		"score": 0,
		"best_score": best_score,
		"highest_tile": highest_tile_achieved,
		"timestamp": Time.get_unix_time_from_system()
	}
	_atomic_write(SAVE_FILE_PATH, JSON.stringify(data, "\t"))

func reset_all_data() -> void:
	best_score = 0
	highest_tile_achieved = 2
	saved_game_available = false
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	if FileAccess.file_exists(SAVE_TEMP_PATH):
		DirAccess.remove_absolute(SAVE_TEMP_PATH)
	best_score_updated.emit(0)

func load_persisted_metadata() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		saved_game_available = false
		return
	var save_dict := load_game()
	if save_dict.is_empty():
		saved_game_available = false
	else:
		saved_game_available = bool(save_dict.get("has_active_game", false))

func _save_metadata_only() -> void:
	# If we have an active save file, load it, update metadata, write back.
	# Otherwise create a new file with just metadata.
	var active_board: Array = []
	var active_score: int = 0
	var has_game: bool = saved_game_available
	
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var txt := file.get_as_text()
			file.close()
			var json := JSON.new()
			if json.parse(txt) == OK and typeof(json.data) == TYPE_DICTIONARY:
				active_board = json.data.get("board", [])
				active_score = int(json.data.get("score", 0))
				has_game = bool(json.data.get("has_active_game", false))
	
	var data := {
		"version": CURRENT_SAVE_VERSION,
		"has_active_game": has_game,
		"board": active_board,
		"score": active_score,
		"best_score": best_score,
		"highest_tile": highest_tile_achieved,
		"timestamp": Time.get_unix_time_from_system()
	}
	_atomic_write(SAVE_FILE_PATH, JSON.stringify(data, "\t"))

func _validate_save_dict(d: Dictionary) -> bool:
	if not d.has("best_score") or typeof(d["best_score"]) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if int(d["best_score"]) < 0:
		return false
	
	if d.get("has_active_game", false) == true:
		if not d.has("board") or typeof(d["board"]) != TYPE_ARRAY:
			return false
		var board: Array = d["board"]
		if board.size() != GRID_SIZE:
			return false
		for row in board:
			if typeof(row) != TYPE_ARRAY or row.size() != GRID_SIZE:
				return false
			for val in row:
				if typeof(val) not in [TYPE_INT, TYPE_FLOAT]:
					return false
				var int_val := int(val)
				if int_val < 0:
					return false
				# Ensure positive values are powers of 2
				if int_val > 0 and (int_val & (int_val - 1)) != 0:
					return false
		if not d.has("score") or typeof(d["score"]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		if int(d["score"]) < 0:
			return false
	return true

func _atomic_write(target_path: String, content: String) -> bool:
	var tmp_file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if not tmp_file:
		push_error("SaveManager: Unable to open temporary save file for writing.")
		return false
	tmp_file.store_string(content)
	tmp_file.close()
	
	# Verify temp file integrity
	if not FileAccess.file_exists(SAVE_TEMP_PATH):
		return false
	
	# Atomic rename/overwrite
	if FileAccess.file_exists(target_path):
		var rm_err := DirAccess.remove_absolute(target_path)
		if rm_err != OK:
			push_warning("SaveManager: Error removing old save: " + str(rm_err))
	
	var ren_err := DirAccess.rename_absolute(SAVE_TEMP_PATH, target_path)
	if ren_err != OK:
		push_error("SaveManager: Error replacing save file: " + str(ren_err))
		return false
	
	return true

func _handle_corruption(reason: String) -> void:
	push_warning("SaveManager: Corrupted save detected (" + reason + "). Safely resetting save state.")
	last_corruption_recovered = true
	saved_game_available = false
	# Preserve best_score if possible or reset cleanly
	clear_saved_game()
	save_data_corrupted_recovered.emit()
