## GhostBoardManager - Handles persistence of ghost boards (death saves)

extends Node

const SAVE_DIR = "user://void_oracle/"
const GHOST_DIR = "user://void_oracle/ghost_boards/"
const MAX_GHOSTS = 10

var active_ghost: Dictionary = {}
var ghost_encounter_active: bool = false

func _ready() -> void:
	_ensure_directories()

func _ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(GHOST_DIR)

## Save current board as a ghost board
func save_ghost(board_state: Dictionary) -> Dictionary:
	var ghost: Dictionary = {
		"board_version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"run_seed": board_state.get("run_seed", 0),
		"zone_reached": board_state.get("zone", 1),
		"peg_layout": board_state.get("pegs", []),
		"active_synergies": board_state.get("active_synergies", []),
		"stability_at_death": board_state.get("stability", 0.0),
		"total_drops": board_state.get("total_drops", 0),
		"relics": board_state.get("relics", [])
	}

	# Save to file
	var ghost_index = _get_next_ghost_index()
	var path = GHOST_DIR + "ghost_%03d.json" % ghost_index
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(ghost, "\t"))
		file.close()

	# Rotate ghosts if needed
	_rotate_ghosts()

	return ghost

## Load a ghost board by index
func load_ghost(index: int) -> Dictionary:
	var path = GHOST_DIR + "ghost_%03d.json" % index
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		return JSON.parse_string(content)
	return {}

## Get the active ghost for the current run encounter
func get_active_ghost() -> Dictionary:
	if ghost_encounter_active:
		return active_ghost
	return {}

## Set a ghost as active for the current run
func set_active_ghost(ghost: Dictionary) -> void:
	active_ghost = ghost
	ghost_encounter_active = true

## Clear the active ghost (encounter completed)
func clear_active_ghost() -> void:
	active_ghost.clear()
	ghost_encounter_active = false

## Get all saved ghosts
func get_all_ghosts() -> Array:
	var ghosts: Array = []
	var i = 0
	while i < MAX_GHOSTS:
		var ghost = load_ghost(i)
		if not ghost.is_empty():
			ghosts.append(ghost)
		i += 1
	return ghosts

func _get_next_ghost_index() -> int:
	var i = 0
	while i < MAX_GHOSTS:
		var path = GHOST_DIR + "ghost_%03d.json" % i
		if not FileAccess.file_exists(path):
			return i
		i += 1
	return 0

func _rotate_ghosts() -> void:
	# If we have MAX_GHOSTS, remove oldest
	var oldest_path = GHOST_DIR + "ghost_%03d.json" % MAX_GHOSTS
	if FileAccess.file_exists(oldest_path):
		DirAccess.remove_absolute(oldest_path)

	# Shift indices
	var i = MAX_GHOSTS - 1
	while i > 0:
		var src = GHOST_DIR + "ghost_%03d.json" % (i - 1)
		var dst = GHOST_DIR + "ghost_%03d.json" % i
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, dst)
		i -= 1
