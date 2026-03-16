## MutationEngine - Tracks peg mutation and state transitions

extends Node

# Peg states from GDD
enum PegState {
	DORMANT,
	BLESSED,
	CURSED,
	MUTANT,
	VOID_TOUCHED,
	SHATTERED
}

# State transition thresholds
const BLESSED_THRESHOLD: int = 3  # hits to become blessed
const CURSED_THRESHOLD: int = 3   # hits to become cursed
const MUTANT_THRESHOLD: int = 5    # total hits for mutant (both states)
const SHATTER_THRESHOLD: int = 10  # hits to shatter

# Hit count thresholds for state changes
const CORRUPTION_HITS: int = 3
const VOID_TOUCHED_HITS: int = 4

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)
	EventBus.run_started.connect(_on_run_started)

func _on_run_started() -> void:
	# Reset any global mutation state
	pass

## Handle peg hit and potentially trigger state change
func _on_peg_hit(peg: Node, ball: Node) -> void:
	var peg_id = peg.get("id", "")
	var peg_data = RunState.get_peg_by_id(peg_id)

	if peg_data.is_empty():
		return

	var old_state = peg_data.get("state", "dormant")
	var hit_count = peg_data.get("hit_count", 0) + 1
	var blessing_hits = peg_data.get("blessing_hits", 0)
	var curse_hits = peg_data.get("curse_hits", 0)

	# Check ball properties for blessing/curse transfer
	var ball_is_blessed = ball.get("is_blessed", false)
	var ball_is_cursed = ball.get("is_cursed", false)
	var ball_is_rot = ball.get("is_rot", false)

	# Update hit counters
	if ball_is_blessed:
		blessing_hits += 1
	if ball_is_cursed or ball_is_rot:
		curse_hits += 1

	# Determine new state
	var new_state = _calculate_new_state(
		old_state, hit_count, blessing_hits, curse_hits
	)

	if new_state != old_state:
		peg_data["state"] = new_state
		peg_data["hit_count"] = hit_count
		peg_data["blessing_hits"] = blessing_hits
		peg_data["curse_hits"] = curse_hits

		# Update the peg in RunState
		_run_state_update_peg(peg_id, peg_data)

		# Emit state change event
		EventBus.emit_signal("peg_state_changed", peg, old_state, new_state)

		# Check for special triggers
		_handle_special_triggers(peg, new_state)

## Calculate the new state based on hit history
func _calculate_new_state(old_state: String, hit_count: int, blessing_hits: int, curse_hits: int) -> String:
	# Mutant check (both blessing and curse hits present)
	if blessing_hits >= 2 and curse_hits >= 2:
		return "mutant"

	# Void-touched check (high hit count with void essence)
	if hit_count >= VOID_TOUCHED_HITS:
		return "void_touched"

	# Shattered check (too many hits without state)
	if hit_count >= SHATTER_THRESHOLD and blessing_hits < 2 and curse_hits < 2:
		return "shattered"

	# Blessed check
	if blessing_hits >= BLESSED_THRESHOLD:
		return "blessed"

	# Cursed check
	if curse_hits >= CURSED_THRESHOLD:
		return "cursed"

	return old_state

## Handle special state triggers
func _handle_special_triggers(peg: Node, new_state: String) -> void:
	match new_state:
		"mutant":
			_spread_mutation(peg)
		"void_touched":
			_become_void_touched(peg)
		"shattered":
			_shatter_peg(peg)

## Mutation spreads to adjacent pegs
func _spread_mutation(source_peg: Node) -> void:
	# Get adjacent pegs and potentially mutate them
	# In production, would use spatial query to find neighbors
	pass

## Peg becomes void-touched
func _become_void_touched(peg: Node) -> void:
	# Void-touched pegs generate Void Essence passively
	RunState.void_essence += 1

## Peg shatters
func _shatter_peg(peg: Node) -> void:
	# Shattered pegs reduce nearby pegs' bonuses
	var peg_id = peg.get("id", "")
	_run_state_update_peg(peg_id, {"state": "shattered"})
	RunState.modify_stability(-5.0)

## Update peg in RunState
func _run_state_update_peg(peg_id: String, updates: Dictionary) -> void:
	var pegs = RunState.pegs
	for i in range(pegs.size()):
		if pegs[i].get("id") == peg_id:
			for key in updates:
				pegs[i][key] = updates[key]
			break
	RunState.pegs = pegs

## Force a peg to a specific state (for shop/abilities)
func set_peg_state(peg_id: String, new_state: String) -> void:
	var peg_data = RunState.get_peg_by_id(peg_id)
	if peg_data.is_empty():
		return

	var old_state = peg_data.get("state", "dormant")
	peg_data["state"] = new_state

	_run_state_update_peg(peg_id, peg_data)
	EventBus.emit_signal("peg_state_changed", null, old_state, new_state)

## Bless a peg (for shop service)
func bless_peg(peg_id: String) -> void:
	set_peg_state(peg_id, "blessed")

## Purify a peg (reset to dormant)
func purify_peg(peg_id: String) -> void:
	set_peg_state(peg_id, "dormant")
	_run_state_update_peg(peg_id, {
		"hit_count": 0,
		"blessing_hits": 0,
		"curse_hits": 0
	})
