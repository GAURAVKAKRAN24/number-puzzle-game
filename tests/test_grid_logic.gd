class_name TestGridLogic
extends RefCounted

const GridManagerRef = preload("res://scripts/grid_manager.gd")

static func run_all() -> int:
	var failed: int = 0
	failed += test_initial_grid()
	failed += test_valid_merge_powers_of_two()
	failed += test_reject_unequal_tiles()
	failed += test_reject_diagonal_tiles()
	failed += test_reject_duplicate_coords()
	failed += test_board_full_and_game_over()
	failed += test_revive_lowest_tiles()
	return failed

static func test_initial_grid() -> int:
	var gm = GridManagerRef.new()
	var initial_spawns := gm.setup_initial_board()
	if initial_spawns.size() != 6:
		printerr("FAIL: test_initial_grid - expected 6 initial spawns, got ", initial_spawns.size())
		return 1
	var empty := gm.get_empty_cells()
	if empty.size() != 19:
		printerr("FAIL: test_initial_grid - expected 19 empty cells, got ", empty.size())
		return 1
	print("PASS: test_initial_grid")
	return 0

static func test_valid_merge_powers_of_two() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	
	# Setup two adjacent '2' tiles at (0, 0) and (1, 0)
	gm.set_cell_value(Vector2i(0, 0), 2)
	gm.set_cell_value(Vector2i(1, 0), 2)
	
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	var val_res := gm.validate_chain(chain)
	if not val_res["valid"]:
		printerr("FAIL: test_valid_merge_powers_of_two - valid chain rejected: ", val_res["reason"])
		return 1
	if val_res["result_value"] != 4:
		printerr("FAIL: test_valid_merge_powers_of_two - expected 4, got ", val_res["result_value"])
		return 1
	
	var exec_res := gm.execute_merge(chain)
	if not exec_res["success"]:
		printerr("FAIL: test_valid_merge_powers_of_two - execute_merge failed: ", exec_res["reason"])
		return 1
	if gm.get_cell_value(Vector2i(1, 0)) != 4:
		printerr("FAIL: test_valid_merge_powers_of_two - target tile was not updated to 4")
		return 1
	if gm.get_cell_value(Vector2i(0, 0)) != 0 and Vector2i(0, 0) not in _get_spawn_positions(exec_res):
		printerr("FAIL: test_valid_merge_powers_of_two - origin tile was not cleared")
		return 1
	
	# Test 3-tile merge: 4 + 4 + 4 -> 4 * 2^(3-1) = 16
	gm.reset_grid()
	gm.set_cell_value(Vector2i(0, 0), 4)
	gm.set_cell_value(Vector2i(0, 1), 4)
	gm.set_cell_value(Vector2i(0, 2), 4)
	var chain3: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
	var res3 := gm.validate_chain(chain3)
	if res3["result_value"] != 16:
		printerr("FAIL: test_valid_merge_powers_of_two - expected 3x4 merge to be 16, got ", res3["result_value"])
		return 1
	
	print("PASS: test_valid_merge_powers_of_two")
	return 0

static func test_reject_unequal_tiles() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	gm.set_cell_value(Vector2i(0, 0), 2)
	gm.set_cell_value(Vector2i(0, 1), 4)
	
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	var res := gm.validate_chain(chain)
	if res["valid"]:
		printerr("FAIL: test_reject_unequal_tiles - unequal tiles (2, 4) should be rejected!")
		return 1
	print("PASS: test_reject_unequal_tiles")
	return 0

static func test_reject_diagonal_tiles() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	gm.set_cell_value(Vector2i(0, 0), 2)
	gm.set_cell_value(Vector2i(1, 1), 2) # Diagonal
	
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1)]
	var res := gm.validate_chain(chain)
	if res["valid"]:
		printerr("FAIL: test_reject_diagonal_tiles - diagonal adjacency must be rejected!")
		return 1
	print("PASS: test_reject_diagonal_tiles")
	return 0

static func test_reject_duplicate_coords() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	gm.set_cell_value(Vector2i(0, 0), 2)
	gm.set_cell_value(Vector2i(0, 1), 2)
	
	# Loop back onto self
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0)]
	var res := gm.validate_chain(chain)
	if res["valid"]:
		printerr("FAIL: test_reject_duplicate_coords - duplicate tile in chain must be rejected!")
		return 1
	print("PASS: test_reject_duplicate_coords")
	return 0

static func test_board_full_and_game_over() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	
	# Fill checkerboard alternating powers of 2 so no two adjacent have equal values
	# Row 0: 2, 4, 2, 4, 2
	# Row 1: 4, 2, 4, 2, 4
	# ...
	for y in range(5):
		for x in range(5):
			if (x + y) % 2 == 0:
				gm.set_cell_value(Vector2i(x, y), 2)
			else:
				gm.set_cell_value(Vector2i(x, y), 4)
	
	if not gm.is_board_full():
		printerr("FAIL: test_board_full_and_game_over - board should be full")
		return 1
	if gm.has_valid_moves():
		printerr("FAIL: test_board_full_and_game_over - checkerboard should have NO valid moves")
		return 1
	if not gm.is_game_over():
		printerr("FAIL: test_board_full_and_game_over - game_over should be true")
		return 1
	
	# Now change one tile so adjacent match exists
	gm.set_cell_value(Vector2i(0, 1), 2) # Now (0,0)=2 and (0,1)=2
	if not gm.has_valid_moves():
		printerr("FAIL: test_board_full_and_game_over - should detect valid move when adjacent match exists")
		return 1
	if gm.is_game_over():
		printerr("FAIL: test_board_full_and_game_over - game_over should be false when valid move exists")
		return 1
	
	print("PASS: test_board_full_and_game_over")
	return 0

static func test_revive_lowest_tiles() -> int:
	var gm = GridManagerRef.new()
	gm.reset_grid()
	gm.set_cell_value(Vector2i(0, 0), 2)
	gm.set_cell_value(Vector2i(1, 0), 2)
	gm.set_cell_value(Vector2i(2, 0), 4)
	gm.set_cell_value(Vector2i(3, 0), 8)
	
	var cleared := gm.revive_clear_lowest_tiles(2)
	if cleared.size() != 2:
		printerr("FAIL: test_revive_lowest_tiles - expected 2 tiles cleared")
		return 1
	if gm.get_cell_value(Vector2i(0, 0)) != 0 or gm.get_cell_value(Vector2i(1, 0)) != 0:
		printerr("FAIL: test_revive_lowest_tiles - lowest tiles '2' were not cleared")
		return 1
	print("PASS: test_revive_lowest_tiles")
	return 0

static func _get_spawn_positions(res: Dictionary) -> Array[Vector2i]:
	var pos_list: Array[Vector2i] = []
	for s in res.get("spawned_tiles", []):
		pos_list.append(s["pos"])
	return pos_list
