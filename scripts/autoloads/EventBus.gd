## EventBus - Global signal hub for cross-system communication
## All major game events pass through here for decoupling

extends Node

# Physics Events
signal peg_hit(peg: Node, ball: Node)
signal ball_lost(ball: Node)
signal ball_entered_pocket(ball: Node, pocket_type: String)

# Peg State Events
signal peg_state_changed(peg: Node, old_state: String, new_state: String)
signal peg_spawned(peg: Node)
signal peg_destroyed(peg: Node)

# Synergy Events
signal synergy_activated(synergy_id: String)
signal synergy_broken(synergy_id: String)
signal synergy_scaled(synergy_id: String, new_tier: int)

# Game Phase Events
signal drop_phase_started()
signal drop_phase_ended()
signal result_phase_started()
signal result_phase_ended()
signal board_phase_started()
signal board_phase_ended()

# Enemy Events
signal enemy_action_started(enemy: Node)
signal enemy_action_ended(enemy: Node)
signal enemy_defeated(enemy: Node)

# Run Events
signal run_started()
signal run_ended(zone_reached: int)
