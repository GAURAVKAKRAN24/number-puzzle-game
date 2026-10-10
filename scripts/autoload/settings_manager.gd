class_name SettingsManagerClass
extends Node

signal settings_changed

const SETTINGS_FILE_PATH: String = "user://settings.json"

var sound_enabled: bool = true
var music_enabled: bool = true
var vibration_enabled: bool = true

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		save_settings()
		return
	
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		push_warning("SettingsManager: Failed to open settings file. Using defaults.")
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("SettingsManager: Corrupted settings file. Resetting to defaults.")
		reset_settings()
		return
	
	var data = json.data
	if typeof(data) == TYPE_DICTIONARY:
		sound_enabled = bool(data.get("sound_enabled", true))
		music_enabled = bool(data.get("music_enabled", true))
		vibration_enabled = bool(data.get("vibration_enabled", true))
	else:
		reset_settings()

func save_settings() -> void:
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"vibration_enabled": vibration_enabled
	}
	
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		settings_changed.emit()
	else:
		push_error("SettingsManager: Failed to write settings to " + SETTINGS_FILE_PATH)

func set_sound(enabled: bool) -> void:
	sound_enabled = enabled
	save_settings()

func set_music(enabled: bool) -> void:
	music_enabled = enabled
	save_settings()

func set_vibration(enabled: bool) -> void:
	vibration_enabled = enabled
	save_settings()

func reset_settings() -> void:
	sound_enabled = true
	music_enabled = true
	vibration_enabled = true
	save_settings()

func vibrate(duration_ms: int = 40) -> void:
	if vibration_enabled:
		if OS.has_feature("android") or OS.has_feature("mobile"):
			Input.vibrate_handheld(duration_ms)
