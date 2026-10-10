class_name Tile
extends Control

signal clicked(tile: Tile)

@export var value: int = 2:
	set(new_val):
		value = new_val
		_update_visuals()

var grid_coord: Vector2i = Vector2i.ZERO
var is_selected: bool = false:
	set(selected):
		is_selected = selected
		_update_selection_visual()

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label

const COLOR_MAP: Dictionary = {
	2: Color("#3a86ff"),     # Vivid blue
	4: Color("#00b4d8"),     # Bright cyan
	8: Color("#06d6a0"),     # Emerald mint
	16: Color("#70e000"),    # Lime green
	32: Color("#ffb703"),    # Warm yellow
	64: Color("#fb8500"),    # Bright orange
	128: Color("#f72585"),   # Electric pink
	256: Color("#b5179e"),   # Magenta
	512: Color("#7209b7"),   # Violet
	1024: Color("#480ca8"),  # Deep purple
	2048: Color("#ffd166"),  # Golden jewel
	4096: Color("#ef476f")   # Radiant crimson
}

func _ready() -> void:
	pivot_offset = size / 2.0
	_update_visuals()

func setup(coord: Vector2i, val: int) -> void:
	grid_coord = coord
	value = val
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if not label or not panel:
		return
	
	label.text = str(value)
	
	# Adjust font size for larger numbers
	if value >= 10000:
		label.add_theme_font_size_override("font_size", 20)
	elif value >= 1000:
		label.add_theme_font_size_override("font_size", 24)
	elif value >= 100:
		label.add_theme_font_size_override("font_size", 30)
	else:
		label.add_theme_font_size_override("font_size", 36)
	
	var base_color: Color = COLOR_MAP.get(value, Color("#ef476f"))
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	
	if is_selected:
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color.WHITE
	
	panel.add_theme_stylebox_override("panel", style)

func _update_selection_visual() -> void:
	_update_visuals()
	pivot_offset = size / 2.0
	var tween := create_tween()
	if is_selected:
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_spawn_animation() -> void:
	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func play_merge_pulse(new_val: int) -> void:
	value = new_val
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func play_clear_animation(callback: Callable = Callable()) -> void:
	pivot_offset = size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	if callback.is_valid():
		tween.chain().tween_callback(callback)
