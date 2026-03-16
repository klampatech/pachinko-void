## SynergyChecker - Watches board for synergy activations

extends Node

# Synergy definitions from GDD
const SYNERGIES: Dictionary = {
	"necrotic_bloom": {
		"tags": ["death", "growth"],
		"tiers": {
			3: {"effect": "Rot pegs deal 3 damage on contact", "curse_risk": "Rot spreads 2x faster"},
			6: {"effect": "All pegs regenerate 1 Stability/drop", "curse_risk": ""}
		}
	},
	"cursed_flame": {
		"tags": ["fire", "cursed"],
		"tiers": {
			3: {"effect": "Burning pegs corrupt adjacent on ignite", "curse_risk": "Board takes 5 dmg/drop"},
			6: {"effect": "Ball moves 20% faster, doubles damage", "curse_risk": ""}
		}
	},
	"void_choir": {
		"tags": ["void", "void", "void"],
		"tiers": {
			3: {"effect": "Every 5th ball becomes a Void Ball", "curse_risk": "Void consumes 1 Blessed peg/run"},
			6: {"effect": "Void Balls open an extra pocket slot", "curse_risk": ""}
		}
	},
	"bleeding_architecture": {
		"tags": ["blood", "foundation"],
		"tiers": {
			3: {"effect": "Stone pegs heal 1 Stability on contact", "curse_risk": "Heart pegs slowly rot"},
			6: {"effect": "Board gains Regen 2 passive", "curse_risk": ""}
		}
	},
	"profane_eye": {
		"tags": ["void", "death"],
		"tiers": {
			3: {"effect": "Eye pegs show enemy next move", "curse_risk": "Eye pegs blind randomly"},
			6: {"effect": "Bone pegs deal double vs revealed moves", "curse_risk": ""}
		}
	}
}

var current_synergies: Array = []

func _ready() -> void:
	EventBus.peg_spawned.connect(_on_peg_spawned)
	EventBus.peg_destroyed.connect(_on_peg_destroyed)
	EventBus.run_started.connect(_on_run_started)

func _on_run_started() -> void:
	current_synergies.clear()
	_check_all_synergies()

func _on_peg_spawned(peg: Node) -> void:
	_check_all_synergies()

func _on_peg_destroyed(peg: Node) -> void:
	_check_all_synergies()

func _check_all_synergies() -> void:
	var pegs = RunState.pegs
	var new_synergies: Array = []

	for synergy_id in SYNERGIES:
		var synergy = SYNERGIES[synergy_id]
		var tag_counts: Dictionary = _count_tags(pegs)

		# Check if synergy requirements are met
		var tier = _calculate_tier(synergy["tags"], tag_counts)

		if tier >= 3:
			new_synergies.append({
				"id": synergy_id,
				"tier": tier,
				"effect": synergy["tiers"][tier]["effect"]
			})

			# Check if this is a new synergy
			if synergy_id not in current_synergies:
				EventBus.emit_signal("synergy_activated", synergy_id)
			elif _get_current_tier(synergy_id) != tier:
				EventBus.emit_signal("synergy_scaled", synergy_id, tier)

	# Check for broken synergies
	for synergy_id in current_synergies:
		if synergy_id not in new_synergies.map(func(s): return s["id"]):
			EventBus.emit_signal("synergy_broken", synergy_id)

	current_synergies = new_synergies.map(func(s): return s["id"])
	RunState.active_synergies = current_synergies

func _count_tags(pegs: Array) -> Dictionary:
	var counts: Dictionary = {}
	for peg in pegs:
		var tags = peg.get("tags", [])
		for tag in tags:
			counts[tag] = counts.get(tag, 0) + 1
	return counts

func _calculate_tier(required_tags: Array, tag_counts: Dictionary) -> int:
	# Find the minimum count among required tags
	var min_count = 999999
	for tag in required_tags:
		var count = tag_counts.get(tag, 0)
		if count < min_count:
			min_count = count
	return min_count

func _get_current_tier(synergy_id: String) -> int:
	for synergy in current_synergies:
		if synergy == synergy_id:
			# This is simplified - in full impl would track tier
			return 6 if synergy_id in RunState.active_synergies else 0
	return 0

func is_synergy_active(synergy_id: String) -> bool:
	return synergy_id in current_synergies

func get_synergy_info(synergy_id: String) -> Dictionary:
	return SYNERGIES.get(synergy_id, {})
