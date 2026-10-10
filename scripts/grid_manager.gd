class_name GridManager
extends RefCounted

signal tile_spawned(pos: Vector2i, value: int)
signal tiles_merged(chain: Array[Vector2i], target_pos: Vector2i, result_value: int)
signal game_over_detected

const GRID_SIZE: int = 5
const INITIAL_TILES_COUNT: int = 6

# 2D Array: grid[y][x] containing tile value or 0 for empty
var grid: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	reset_grid()

func reset_grid() -> void:
	grid.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append(0)
		grid.append(row)

func setup_initial_board() -> Array[Dictionary]:
	reset_grid()
	var spawned: Array[Dictionary] = []
	for i in range(INITIAL_TILES_COUNT):
		var spawn_info := spawn_random_tile()
		if not spawn_info.is_empty():
			spawned.append(spawn_info)
	return spawned

func get_cell_value(pos: Vector2i) -> int:
	if not is_valid_coord(pos):
		return 0
	return int(grid[pos.y][pos.x])

func set_cell_value(pos: Vector2i, val: int) -> void:
	if is_valid_coord(pos):
		grid[pos.y][pos.x] = val

func is_valid_coord(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func is_orthogonal_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)

func get_empty_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] == 0:
				empty.append(Vector2i(x, y))
	return empty

func get_highest_value() -> int:
	var highest: int = 2
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] > highest:
				highest = grid[y][x]
	return highest

func get_next_spawn_value() -> int:
	var highest := get_highest_value()
	var roll := rng.randf()
	if highest >= 128:
		if roll < 0.60:
			return 2
		elif roll < 0.90:
			return 4
		else:
			return 8
	else:
		if roll < 0.70:
			return 2
		else:
			return 4

func spawn_random_tile() -> Dictionary:
	var empty := get_empty_cells()
	if empty.is_empty():
		return {}
	
	var random_index := rng.randi_range(0, empty.size() - 1)
	var target_cell: Vector2i = empty[random_index]
	var val := get_next_spawn_value()
	
	set_cell_value(target_cell, val)
	tile_spawned.emit(target_cell, val)
	return {"pos": target_cell, "val": val}

func calculate_merge_result(base_value: int, chain_length: int) -> int:
	if chain_length < 2 or base_value <= 0:
		return base_value
	# Formula: ResultValue = V * 2^(N - 1)
	var power := chain_length - 1
	var multiplier := int(pow(2, power))
	return base_value * multiplier

func validate_chain(chain: Array[Vector2i]) -> Dictionary:
	if chain.size() < 2:
		return {"valid": false, "reason": "Chain must have at least 2 tiles."}
	
	# Verify duplicate coords
	var visited: Dictionary = {}
	for pos in chain:
		if not is_valid_coord(pos):
			return {"valid": false, "reason": "Coordinate out of bounds: " + str(pos)}
		var key := str(pos.x) + "_" + str(pos.y)
		if visited.has(key):
			return {"valid": false, "reason": "Duplicate coordinate in chain."}
		visited[key] = true
	
	# Check adjacent connectivity (orthogonal only)
	for i in range(chain.size() - 1):
		var cur: Vector2i = chain[i]
		var nxt: Vector2i = chain[i + 1]
		if not is_orthogonal_adjacent(cur, nxt):
			return {"valid": false, "reason": "Tiles are not orthogonally adjacent."}
	
	# Check matching values
	var first_val := get_cell_value(chain[0])
	if first_val <= 0:
		return {"valid": false, "reason": "First tile is empty."}
	
	for i in range(1, chain.size()):
		var val := get_cell_value(chain[i])
		if val != first_val:
			return {"valid": false, "reason": "Tile values do not match (" + str(val) + " != " + str(first_val) + ")."}
	
	var result_val := calculate_merge_result(first_val, chain.size())
	return {
		"valid": true,
		"reason": "OK",
		"base_value": first_val,
		"result_value": result_val
	}

func execute_merge(chain: Array[Vector2i]) -> Dictionary:
	var validation := validate_chain(chain)
	if not validation["valid"]:
		return {"success": false, "reason": validation["reason"]}
	
	var target_pos: Vector2i = chain[-1]
	var result_val: int = validation["result_value"]
	var cleared_positions: Array[Vector2i] = []
	
	# Clear previous tiles in chain
	for i in range(chain.size() - 1):
		var p: Vector2i = chain[i]
		set_cell_value(p, 0)
		cleared_positions.append(p)
	
	# Update target tile
	set_cell_value(target_pos, result_val)
	tiles_merged.emit(chain, target_pos, result_val)
	
	# Spawn regular turn tile
	var spawned_tiles: Array[Dictionary] = []
	var primary_spawn := spawn_random_tile()
	if not primary_spawn.is_empty():
		spawned_tiles.append(primary_spawn)
	
	# Anti-deadlock check: if empty cells remain but board has no valid moves, spawn additional tile
	var empty := get_empty_cells()
	var deadlock_attempts := 0
	while not empty.is_empty() and not has_valid_moves() and deadlock_attempts < 2:
		var extra_spawn := spawn_random_tile()
		if extra_spawn.is_empty():
			break
		spawned_tiles.append(extra_spawn)
		empty = get_empty_cells()
		deadlock_attempts += 1
	
	var game_over := is_game_over()
	if game_over:
		game_over_detected.emit()
	
	return {
		"success": true,
		"target_pos": target_pos,
		"result_value": result_val,
		"cleared_positions": cleared_positions,
		"spawned_tiles": spawned_tiles,
		"is_game_over": game_over
	}

func has_valid_moves() -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var val: int = grid[y][x]
			if val == 0:
				continue
			# Check right neighbor
			if x + 1 < GRID_SIZE and grid[y][x + 1] == val:
				return true
			# Check down neighbor
			if y + 1 < GRID_SIZE and grid[y + 1][x] == val:
				return true
	return false

func is_board_full() -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] == 0:
				return false
	return true

func is_game_over() -> bool:
	return is_board_full() and not has_valid_moves()

func revive_clear_lowest_tiles(count: int = 3) -> Array[Vector2i]:
	var tile_list: Array[Dictionary] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var v: int = grid[y][x]
			if v > 0:
				tile_list.append({"pos": Vector2i(x, y), "val": v})
	
	if tile_list.is_empty():
		return []
	
	# Sort ascending by value
	tile_list.sort_custom(func(a: Dictionary, b: Dictionary): return a["val"] < b["val"])
	
	var cleared: Array[Vector2i] = []
	var limit := mini(count, tile_list.size())
	for i in range(limit):
		var p: Vector2i = tile_list[i]["pos"]
		set_cell_value(p, 0)
		cleared.append(p)
	
	return cleared

func get_grid_state() -> Array:
	var copy: Array = []
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append(grid[y][x])
		copy.append(row)
	return copy

func load_grid_state(data: Array) -> bool:
	if data.size() != GRID_SIZE:
		return false
	for y in range(GRID_SIZE):
		if typeof(data[y]) != TYPE_ARRAY or data[y].size() != GRID_SIZE:
			return false
		for x in range(GRID_SIZE):
			grid[y][x] = int(data[y][x])
	return true
