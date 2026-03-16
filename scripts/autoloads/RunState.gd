## RunState - Singleton managing current run data and player progress

extends Node

# Player resources
var stability: float = 100.0
var gold: int = 0
var void_essence: int = 0
var ball_count: int = 1
var total_drops: int = 0

# Current run info
var zone: int = 1
var run_seed: int = 0
var encounter_index: int = 0

# Board state
var pegs: Array = []
var active_synergies: Array = []
var relics: Array = []

# Oracle class (unlocked after first win)
var oracle_class: String = ""

func _ready() -> void:
	run_seed = Time.get_unix_time_from_system()

func start_new_run() -> void:
	stability = 100.0
	gold = 0
	void_essence = 0
	ball_count = 1
	total_drops = 0
	zone = 1
	encounter_index = 0
	pegs.clear()
	active_synergies.clear()
	relics.clear()
	run_seed = Time.get_unix_time_from_system()
	EventBus.emit_signal("run_started")

func add_peg(peg_data: Dictionary) -> void:
	pegs.append(peg_data)

func remove_peg(peg_id: String) -> void:
	pegs = pegs.filter(func(p): return p.get("id") != peg_id)

func get_peg_by_id(peg_id: String) -> Dictionary:
	for peg in pegs:
		if peg.get("id") == peg_id:
			return peg
	return {}

func add_relic(relic_id: String) -> void:
	if relic_id not in relics:
		relics.append(relic_id)

func has_relic(relic_id: String) -> bool:
	return relic_id in relics

func modify_stability(amount: float) -> void:
	stability = clampf(stability + amount, 0.0, 100.0)
	if stability <= 0:
		end_run()

func end_run() -> void:
	EventBus.emit_signal("run_ended", zone)

func get_board_state() -> Dictionary:
	return {
		"stability": stability,
		"gold": gold,
		"void_essence": void_essence,
		"ball_count": ball_count,
		"total_drops": total_drops,
		"zone": zone,
		"pegs": pegs.duplicate(true),
		"active_synergies": active_synergies.duplicate(),
		"relics": relics.duplicate(),
		"run_seed": run_seed,
		"oracle_class": oracle_class
	}
