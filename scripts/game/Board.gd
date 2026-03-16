## Board - Main game scene and physics world

extends Node2D

# Board dimensions
const BOARD_WIDTH: float = 600.0
const BOARD_HEIGHT: float = 900.0

# Pocket types
enum PocketType {
	DAMAGE,
	HEAL,
	GOLD,
	VOID,
	CHAOS
}

# Game phases
enum GamePhase {
	DROP_PHASE,
	RESULT_PHASE,
	BOARD_PHASE,
	NAVIGATION_PHASE
}

var current_phase: GamePhase = GamePhase.BOARD_PHASE

@onready var peg_container: Node2D = $PegContainer
@onready var pockets: Node2D = $Pockets
@onready var ball_spawner: Node2D = $BallSpawner
@onready var stability_bar: ProgressBar = $UI/StabilityBar
@onready var gold_label: Label = $UI/GoldLabel
@onready var ball_count_label: Label = $UI/BallCountLabel
@onready var phase_label: Label = $UI/PhaseLabel

# Pocket definitions (position -> type mapping)
var pocket_types: Dictionary = {}

func _ready() -> void:
	_setup_pockets()
	_connect_signals()
	_update_ui()

func _setup_pockets() -> void:
	# Map pocket positions to types based on scene layout
	for pocket in pockets.get_children():
		if pocket is Area2D:
			var pos = pocket.position
			if pos.x < 150:
				pocket_types[pos] = PocketType.DAMAGE
			elif pos.x < 225:
				pocket_types[pos] = PocketType.GOLD
			elif pos.x < 375:
				pocket_types[pos] = PocketType.HEAL
			elif pos.x < 450:
				pocket_types[pos] = PocketType.VOID
			else:
				pocket_types[pos] = PocketType.DAMAGE

func _connect_signals() -> void:
	EventBus.ball_entered_pocket.connect(_on_ball_entered_pocket)
	EventBus.ball_lost.connect(_on_ball_lost)
	EventBus.drop_phase_started.connect(_on_drop_phase_started)
	EventBus.drop_phase_ended.connect(_on_drop_phase_ended)
	EventBus.run_started.connect(_on_run_started)

func _process(_delta: float) -> void:
	# Update UI
	_update_ui()

func _update_ui() -> void:
	if stability_bar:
		stability_bar.value = RunState.stability
	if gold_label:
		gold_label.text = "Gold: %d" % RunState.gold
	if ball_count_label:
		ball_count_label.text = "Balls: %d" % RunState.ball_count
	if phase_label:
		phase_label.text = _get_phase_name()

func _get_phase_name() -> String:
	match current_phase:
		GamePhase.DROP_PHASE:
			return "Drop Phase"
		GamePhase.RESULT_PHASE:
			return "Result Phase"
		GamePhase.BOARD_PHASE:
			return "Board Phase"
		GamePhase.NAVIGATION_PHASE:
			return "Navigation Phase"
	return "Unknown"

func _on_run_started() -> void:
	current_phase = GamePhase.BOARD_PHASE

func _on_drop_phase_started() -> void:
	current_phase = GamePhase.DROP_PHASE

func _on_drop_phase_ended() -> void:
	current_phase = GamePhase.RESULT_PHASE

func _on_ball_entered_pocket(ball: Node, pocket_type: String) -> void:
	# Apply pocket effects
	match pocket_type:
		"damage", "DMG":
			# Deal damage to enemy
			pass
		"heal", "HEAL":
			RunState.modify_stability(5.0)
		"gold", "GOLD":
			RunState.gold += 10
		"void", "VOID":
			RunState.void_essence += 1

func _on_ball_lost(ball: Node) -> void:
	# Ball fell off screen without entering pocket
	pass

func start_drop_phase() -> void:
	EventBus.emit_signal("drop_phase_started")
	current_phase = GamePhase.DROP_PHASE

func end_drop_phase() -> void:
	EventBus.emit_signal("drop_phase_ended")
	current_phase = GamePhase.RESULT_PHASE

func add_peg(peg_scene: PackedScene, position: Vector2) -> Node:
	var peg = peg_scene.instantiate()
	peg.position = position
	peg_container.add_child(peg)
	return peg

func remove_peg(peg: Node) -> void:
	peg.queue_free()

func get_peg_at_position(pos: Vector2, radius: float = 20.0) -> Array:
	var results: Array = []
	for peg in peg_container.get_children():
		if peg.position.distance_to(pos) < radius:
			results.append(peg)
	return results

func get_pocket_at_position(pos: Vector2) -> Dictionary:
	for pocket in pockets.get_children():
		if pocket is Area2D and pocket.position.distance_to(pos) < 40:
			return {
				"pocket": pocket,
				"type": pocket_types.get(pocket.position, "unknown")
			}
	return {}
