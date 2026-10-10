class_name GameManager
extends Control

enum State {
	PLAYING,
	ANIMATING,
	PAUSED,
	GAME_OVER
}

var current_state: State = State.PLAYING
var grid_manager: GridManager
var score_manager: ScoreManager

var is_dragging: bool = false
var selected_chain: Array[Vector2i] = []

# Node references
@onready var grid_container: GridContainer = %GridContainer
@onready var board_panel: Panel = %BoardPanel
@onready var line_2d: Line2D = %SelectionLine
@onready var current_score_label: Label = %CurrentScoreLabel
@onready var best_score_label: Label = %BestScoreLabel
@onready var milestone_banner: Panel = %MilestoneBanner
@onready var milestone_label: Label = %MilestoneLabel
@onready var pause_dialog: PauseDialog = %PauseDialog
@onready var confirmation_dialog: ConfirmationDialogCustom = %ConfirmationDialog
@onready var how_to_play_dialog: HowToPlayDialog = %HowToPlayDialog
@onready var game_over_dialog: GameOverDialog = %GameOverDialog

const TILE_SCENE = preload("res://scenes/components/tile.tscn")
const BOARD_CELL_SCENE = preload("res://scenes/components/board_cell.tscn")

# 2D array of Tile node instances or null
var tile_nodes: Array = []
var cell_nodes: Array = []
var _milestone_shown: Dictionary = {}

func _ready() -> void:
	grid_manager = GridManager.new()
	var best_score: int = 0
	if Engine.has_singleton("SaveManager"):
		var sm = Engine.get_singleton("SaveManager")
		best_score = sm.get_best_score()
	else:
		var sm_node := get_node_or_null("/root/SaveManager")
		if sm_node and sm_node.has_method("get_best_score"):
			best_score = sm_node.get_best_score()
	
	score_manager = ScoreManager.new(0, best_score)
	score_manager.score_changed.connect(_on_score_changed)
	score_manager.new_best_score_reached.connect(_on_new_best_score)
	
	_setup_dialog_connections()
	_build_board_ui()
	_start_or_resume_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_android_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if current_state == State.PLAYING:
			_pause_game()

func _setup_dialog_connections() -> void:
	pause_dialog.resume_requested.connect(_resume_game)
	pause_dialog.restart_requested.connect(_prompt_restart)
	pause_dialog.how_to_play_requested.connect(func(): how_to_play_dialog.open())
	pause_dialog.menu_requested.connect(_return_to_main_menu)
	
	game_over_dialog.play_again_requested.connect(_restart_clean_game)
	game_over_dialog.home_requested.connect(_return_to_main_menu)
	game_over_dialog.second_chance_requested.connect(_watch_ad_for_second_chance)
	
	%PauseButton.pressed.connect(_pause_game)
	%RestartButton.pressed.connect(_prompt_restart)

func _build_board_ui() -> void:
	# Clean existing nodes
	for child in grid_container.get_children():
		child.queue_free()
	
	tile_nodes.clear()
	cell_nodes.clear()
	
	for y in range(GridManager.GRID_SIZE):
		var tile_row: Array = []
		var cell_row: Array = []
		for x in range(GridManager.GRID_SIZE):
			var cell := BOARD_CELL_SCENE.instantiate()
			grid_container.add_child(cell)
			cell_row.append(cell)
			tile_row.append(null)
		cell_nodes.append(cell_row)
		tile_nodes.append(tile_row)

func _start_or_resume_game() -> void:
	var sm_node := get_node_or_null("/root/SaveManager")
	var has_saved := false
	var saved_dict := {}
	if sm_node and sm_node.has_method("has_saved_game"):
		has_saved = sm_node.has_saved_game()
		if has_saved:
			saved_dict = sm_node.load_game()
	
	if has_saved and not saved_dict.is_empty():
		var board: Array = saved_dict.get("board", [])
		var loaded_score: int = int(saved_dict.get("score", 0))
		var loaded_best: int = int(saved_dict.get("best_score", 0))
		grid_manager.load_grid_state(board)
		score_manager.current_score = loaded_score
		score_manager.best_score = loaded_best
		_render_existing_board()
		_on_score_changed(loaded_score, 0)
	else:
		_start_new_game()

func _start_new_game() -> void:
	_clear_all_tiles()
	score_manager.reset(score_manager.best_score)
	game_over_dialog.reset_run()
	var initial_spawns := grid_manager.setup_initial_board()
	for spawn in initial_spawns:
		_create_tile_node(spawn["pos"], spawn["val"], true)
	_save_state()

func _render_existing_board() -> void:
	_clear_all_tiles()
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var v := grid_manager.get_cell_value(Vector2i(x, y))
			if v > 0:
				_create_tile_node(Vector2i(x, y), v, false)

func _clear_all_tiles() -> void:
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			if tile_nodes[y][x] != null:
				tile_nodes[y][x].queue_free()
				tile_nodes[y][x] = null

func _create_tile_node(coord: Vector2i, val: int, animate_spawn: bool = false) -> Tile:
	var tile: Tile = TILE_SCENE.instantiate()
	tile.setup(coord, val)
	
	# Add tile on top of corresponding background cell slot
	var cell: Control = cell_nodes[coord.y][coord.x]
	cell.add_child(tile)
	tile.position = Vector2.ZERO
	tile.size = cell.size
	
	tile_nodes[coord.y][coord.x] = tile
	if animate_spawn:
		tile.play_spawn_animation()
	return tile

# Touch & Drag Input Handling
func _gui_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_touch_start(event.position)
			else:
				_handle_touch_end()
	elif event is InputEventMouseMotion and is_dragging:
		_handle_touch_drag(event.position)

func _handle_touch_start(global_pos: Vector2) -> void:
	var coord := _get_coord_at_position(global_pos)
	if coord == Vector2i(-1, -1):
		return
	
	var val := grid_manager.get_cell_value(coord)
	if val <= 0:
		return
	
	is_dragging = true
	selected_chain.clear()
	_add_to_chain(coord)

func _handle_touch_drag(global_pos: Vector2) -> void:
	var coord := _get_coord_at_position(global_pos)
	if coord == Vector2i(-1, -1) or selected_chain.is_empty():
		return
	
	var last_coord: Vector2i = selected_chain[-1]
	if coord == last_coord:
		return
	
	# Check backtracking (undoing previous tile in chain)
	if selected_chain.size() >= 2 and coord == selected_chain[-2]:
		_remove_from_chain()
		return
	
	# Validate adjacency, equivalence, and uniqueness
	if grid_manager.is_orthogonal_adjacent(last_coord, coord):
		if coord not in selected_chain:
			var first_val := grid_manager.get_cell_value(selected_chain[0])
			var cur_val := grid_manager.get_cell_value(coord)
			if cur_val == first_val:
				_add_to_chain(coord)

func _handle_touch_end() -> void:
	if not is_dragging:
		return
	is_dragging = false
	line_2d.clear_points()
	
	if selected_chain.size() >= 2:
		_execute_selected_merge()
	else:
		_deselect_all_in_chain()

func _add_to_chain(coord: Vector2i) -> void:
	selected_chain.append(coord)
	var tile: Tile = tile_nodes[coord.y][coord.x]
	if tile:
		tile.is_selected = true
	
	_update_selection_line()
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_select"):
		am.play_select(selected_chain.size())
	
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("vibrate"):
		sm.vibrate(25)

func _remove_from_chain() -> void:
	if selected_chain.is_empty():
		return
	var last_coord: Vector2i = selected_chain.pop_back()
	var tile: Tile = tile_nodes[last_coord.y][last_coord.x]
	if tile:
		tile.is_selected = false
	
	_update_selection_line()
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_tap"):
		am.play_tap()

func _deselect_all_in_chain() -> void:
	for c in selected_chain:
		var tile: Tile = tile_nodes[c.y][c.x]
		if tile:
			tile.is_selected = false
	selected_chain.clear()
	line_2d.clear_points()

func _update_selection_line() -> void:
	line_2d.clear_points()
	for c in selected_chain:
		var cell: Control = cell_nodes[c.y][c.x]
		var center := cell.global_position + (cell.size / 2.0)
		# Convert to line2d local coords
		var local_pt := line_2d.to_local(center)
		line_2d.add_point(local_pt)

func _get_coord_at_position(pos: Vector2) -> Vector2i:
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var cell: Control = cell_nodes[y][x]
			if cell.get_global_rect().has_point(pos):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _execute_selected_merge() -> void:
	current_state = State.ANIMATING
	var chain_copy: Array[Vector2i] = selected_chain.duplicate()
	var target_coord: Vector2i = chain_copy[-1]
	
	var result := grid_manager.execute_merge(chain_copy)
	if not result["success"]:
		_deselect_all_in_chain()
		current_state = State.PLAYING
		return
	
	var result_val: int = result["result_value"]
	var target_tile: Tile = tile_nodes[target_coord.y][target_coord.x]
	
	# Deselect
	for c in chain_copy:
		var t: Tile = tile_nodes[c.y][c.x]
		if t:
			t.is_selected = false
	selected_chain.clear()
	
	# Audio & Haptics
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_merge"):
		am.play_merge()
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("vibrate"):
		sm.vibrate(45)
	
	# Clear previous tiles with animation
	for c in result["cleared_positions"]:
		var clr_tile: Tile = tile_nodes[c.y][c.x]
		if clr_tile:
			clr_tile.play_clear_animation(func(): clr_tile.queue_free())
			tile_nodes[c.y][c.x] = null
	
	# Pulse target tile
	if target_tile:
		target_tile.play_merge_pulse(result_val)
	
	# Add score
	score_manager.add_merge_score(result_val, chain_copy.size())
	
	# Spawn new tiles after short delay
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(func():
		for spawn in result["spawned_tiles"]:
			_create_tile_node(spawn["pos"], spawn["val"], true)
		
		_save_state()
		_check_milestone(result_val)
		
		if result["is_game_over"]:
			_trigger_game_over()
		else:
			current_state = State.PLAYING
	)

func _check_milestone(val: int) -> void:
	if val >= 128 and not _milestone_shown.has(val):
		_milestone_shown[val] = true
		milestone_label.text = str(val) + " CREATED!"
		milestone_banner.visible = true
		milestone_banner.modulate.a = 0.0
		milestone_banner.scale = Vector2(0.8, 0.8)
		milestone_banner.pivot_offset = milestone_banner.size / 2.0
		
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_milestone"):
			am.play_milestone()
		
		var tween := create_tween()
		tween.tween_property(milestone_banner, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(milestone_banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(1.2)
		tween.tween_property(milestone_banner, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): milestone_banner.visible = false)

func _trigger_game_over() -> void:
	current_state = State.GAME_OVER
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_game_over"):
		am.play_game_over()
	
	# Check interstitial ad cap
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_interstitial_on_game_over"):
		adm.show_interstitial_on_game_over()
	
	# Open Game Over dialog
	game_over_dialog.open(score_manager.current_score, score_manager.best_score, true)

func _watch_ad_for_second_chance() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_rewarded_ad"):
		adm.show_rewarded_ad(_apply_second_chance_revive)
	else:
		_apply_second_chance_revive()

func _apply_second_chance_revive() -> void:
	game_over_dialog.mark_second_chance_used()
	game_over_dialog.close()
	
	# Clear 3 lowest tiles to free space
	var cleared_positions := grid_manager.revive_clear_lowest_tiles(3)
	for c in cleared_positions:
		var tile: Tile = tile_nodes[c.y][c.x]
		if tile:
			tile.play_clear_animation(func(): tile.queue_free())
			tile_nodes[c.y][c.x] = null
	
	_save_state()
	current_state = State.PLAYING

func _on_score_changed(score: int, _added: int) -> void:
	current_score_label.text = str(score)

func _on_new_best_score(new_best: int) -> void:
	best_score_label.text = str(new_best)

func _pause_game() -> void:
	if current_state == State.PLAYING:
		current_state = State.PAUSED
		_save_state()
		pause_dialog.open()

func _resume_game() -> void:
	current_state = State.PLAYING

func _prompt_restart() -> void:
	confirmation_dialog.prompt(
		"Restart Game?",
		"Are you sure you want to discard this game and start over?",
		"Restart"
	)
	confirmation_dialog.confirmed.connect(_restart_clean_game, CONNECT_ONE_SHOT)

func _restart_clean_game() -> void:
	pause_dialog.close()
	_start_new_game()
	current_state = State.PLAYING

func _return_to_main_menu() -> void:
	_save_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _save_state() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("save_game"):
		sm.save_game(grid_manager.get_grid_state(), score_manager.current_score, grid_manager.get_highest_value())

func _handle_android_back() -> void:
	if how_to_play_dialog.visible:
		how_to_play_dialog.visible = false
	elif confirmation_dialog.visible:
		confirmation_dialog.visible = false
	elif pause_dialog.visible:
		_resume_game()
	elif game_over_dialog.visible:
		_return_to_main_menu()
	elif current_state == State.PLAYING:
		_pause_game()
	else:
		_return_to_main_menu()
