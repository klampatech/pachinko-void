## BasePeg - Base class for all peg types

extends StaticBody2D

# Peg type identifier
@export var peg_type: String = "stone"

# Peg state (from GDD)
enum PegState {
	DORMANT,
	BLESSED,
	CURSED,
	MUTANT,
	VOID_TOUCHED,
	SHATTERED
}

var current_state: PegState = PegState.DORMANT

# Peg data
var peg_id: String = ""
var hit_count: int = 0
var blessing_hits: int = 0
var curse_hits: int = 0

# Tags for synergy checking
var synergy_tags: Array[String] = ["foundation"]

# Visual components
@onready var visuals: Node2D = $Visuals
@onready var circle: Polygon2D = $Visuals/Circle

# Physics material (set by derived classes)
var physics_material: PhysicsMaterial

func _ready() -> void:
	# Add to peg group
	add_to_group("peg")

	# Generate unique ID
	peg_id = "%s_%d" % [peg_type, Time.get_unix_time_from_system()]

	# Load peg definition
	_load_peg_definition()

	# Connect collision signal
	body_entered.connect(_on_body_entered)

func _load_peg_definition() -> void:
	# Load from JSON definition
	var file_path = "res://data/pegs/peg_definitions.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var json = JSON.parse_string(content)
		if json and json.has(peg_type):
			var def = json[peg_type]
			synergy_tags = def.get("tags", [])

			# Setup physics material
			_setup_physics_material(
				def.get("restitution", 0.6),
				def.get("friction", 0.1)
			)

func _setup_physics_material(restitution: float, friction: float) -> void:
	physics_material = PhysicsMaterial.new()
	physics_material.bounce = restitution
	physics_material.friction = friction
	physics_material_override = physics_material

func _on_body_entered(body: RigidBody2D) -> void:
	if body.is_in_group("ball"):
		# Emit peg hit event
		EventBus.emit_signal("peg_hit", self, body)

		# Increment hit count
		hit_count += 1

		# Register with RunState
		_register_hit(body)

		# Handle special abilities
		_handle_special_ability(body)

		# Update visual
		_update_visual()

func _register_hit(ball: Node) -> void:
	# Update RunState
	var peg_data = RunState.get_peg_by_id(peg_id)
	if peg_data.is_empty():
		# First hit - register new peg
		peg_data = {
			"id": peg_id,
			"type": peg_type,
			"position": position,
			"state": _state_to_string(current_state),
			"hit_count": hit_count,
			"tags": synergy_tags.duplicate()
		}
		RunState.add_peg(peg_data)
	else:
		# Update existing peg data
		peg_data["hit_count"] = hit_count
		peg_data["state"] = _state_to_string(current_state)

func _handle_special_ability(ball: Node) -> void:
	# Load definition for special ability
	var file_path = "res://data/pegs/peg_definitions.json"
	if not FileAccess.file_exists(file_path):
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.parse_string(content)
	if not json or not json.has(peg_type):
		return

	var def = json[peg_type]
	var special = def.get("special")

	match special:
		"heals_stability":
			RunState.modify_stability(5.0)
		"spawns_sprout":
			# TODO: Spawn adjacent sprout peg
			pass
		"ignites_adjacent":
			# TODO: Ignite adjacent pegs
			pass
		"reveals_pockets":
			# TODO: Show pocket preview
			pass
		"splits_ball":
			# TODO: Create 2 more balls
			ball.split()
		"teleports_ball":
			# TODO: Teleport ball to random pocket
			pass

func _update_visual() -> void:
	# Update color based on state
	var color: Color

	match current_state:
		PegState.DORMANT:
			color = Color(0.5, 0.5, 0.55)  # Grey
		PegState.BLESSED:
			color = Color(1.0, 0.85, 0.4)  # Gold shimmer
		PegState.CURSED:
			color = Color(0.8, 0.2, 0.2)   # Crimson
		PegState.MUTANT:
			color = Color(0.3, 0.9, 0.4)  # Green bioluminescent
		PegState.VOID_TOUCHED:
			color = Color(0.2, 0.1, 0.3)  # Dark with stars
		PegState.SHATTERED:
			color = Color(0.2, 0.2, 0.25)  # Cracked dark

	if circle:
		circle.color = color

func set_state(new_state: PegState) -> void:
	var old_state = current_state
	current_state = new_state
	_update_visual()

	EventBus.emit_signal("peg_state_changed", self, _state_to_string(old_state), _state_to_string(new_state))

func _state_to_string(state: PegState) -> String:
	match state:
		PegState.DORMANT: return "dormant"
		PegState.BLESSED: return "blessed"
		PegState.CURSED: return "cursed"
		PegState.MUTANT: return "mutant"
		PegState.VOID_TOUCHED: return "void_touched"
		PegState.SHATTERED: return "shattered"
	return "dormant"

func get_state_from_string(state_str: String) -> PegState:
	match state_str:
		"blessed": return PegState.BLESSED
		"cursed": return PegState.CURSED
		"mutant": return PegState.MUTANT
		"void_touched": return PegState.VOID_TOUCHED
		"shattered": return PegState.SHATTERED
	return PegState.DORMANT
