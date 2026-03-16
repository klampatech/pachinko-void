# Void Oracle — Implementation Plan

> **For Claude:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a physics-driven roguelike pachinko game in Godot where the board is the player's character.

**Architecture:**
- Godot 4.3+ with GDScript, GL Compatibility renderer (WebGL2)
- 6 AutoLoad singletons for global state management (EventBus, RunState, GhostBoardManager, SynergyChecker, AudioManager, MutationEngine)
- All systems communicate via EventBus signals - no direct method calls between systems
- Data-driven: all game values from JSON files (peg definitions, synergy definitions, enemy data, events)

**Tech Stack:**
- Godot 4.3+ (GDScript 2.0)
- Jolt Physics (Godot 4.3+ integrated)
- Shaders: GLSL-like Godot shading language
- Save: FileAccess + JSON to user:// path (IndexedDB on web)

---

## Project Status: NO CODE EXISTS

**Critical Gap:** The `src/` directory is empty. This is a greenfield project requiring complete Godot project setup before any gameplay implementation.

---

## Phase 1: Project Foundation (Priority: Critical)

### Task 1.1: Initialize Godot Project Structure

**Files:**
- Create: `res://project.godot` (Godot project file)
- Create: `res://scenes/game/`
- Create: `res://scenes/menus/`
- Create: `res://scenes/map/`
- Create: `res://scripts/autoloads/`
- Create: `res://scripts/systems/`
- Create: `res://scripts/pegs/`
- Create: `res://data/pegs/`
- Create: `res://data/synergies/`
- Create: `res://data/enemies/`
- Create: `res://data/events/`
- Create: `res://shaders/`
- Create: `res://assets/audio/`
- Create: `res://assets/textures/`

**Step 1: Create project.godot**

```ini
config_version=5
[application]
config/name="Void Oracle"
run/main_scene="res://scenes/menus/MainMenu.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")
config/icon="res://assets/icon.svg"

[autoload]
EventBus="*res://scripts/autoloads/EventBus.gd"
RunState="*res://scripts/autoloads/RunState.gd"
GhostBoardManager="*res://scripts/autoloads/GhostBoardManager.gd"
SynergyChecker="*res://scripts/autoloads/SynergyChecker.gd"
AudioManager="*res://scripts/autoloads/AudioManager.gd"
MutationEngine="*res://scripts/autoloads/MutationEngine.gd"

[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/size/mode=2
window/stretch/mode="canvas_items"

[physics]
common/physics_ticks_per_second=120
2d/default_gravity=980.0

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

**Step 2: Create .gitignore**

```
.godot/
*.import
*.ogg
*.wav
*.png
*.jpg
*.jpeg
*.webp
*.svg
.DS_Store
user://
```

**Step 3: Commit**

---

### Task 1.2: Create AutoLoad Singletons (Skeleton)

**Files:**
- Create: `res://scripts/autoloads/EventBus.gd`
- Create: `res://scripts/autoloads/RunState.gd`
- Create: `res://scripts/autoloads/GhostBoardManager.gd`
- Create: `res://scripts/autoloads/SynergyChecker.gd`
- Create: `res://scripts/autoloads/AudioManager.gd`
- Create: `res://scripts/autoloads/MutationEngine.gd`

**Step 1: Create EventBus.gd**

```gdscript
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
```

**Step 2: Create RunState.gd**

```gdscript
extends Node

var stability: float = 100.0
var gold: int = 0
var void_essence: int = 0
var ball_count: int = 1
var total_drops: int = 0
var zone: int = 1

var pegs: Array = []
var active_synergies: Array = []
var relics: Array = []

var run_seed: int = 0

func _ready() -> void:
	run_seed = randi()

func snapshot_board() -> Dictionary:
	# Returns board state for ghost saving
	pass

func reset() -> void:
	stability = 100.0
	gold = 0
	void_essence = 0
	ball_count = 1
	total_drops = 0
	zone = 1
	pegs.clear()
	active_synergies.clear()
	relics.clear()
	run_seed = randi()
```

**Step 3: Create remaining skeletons (GhostBoardManager, SynergyChecker, AudioManager, MutationEngine)**
- Minimal stubs that extend Node
- Will be implemented in later phases

**Step 4: Verify project settings shows 6 autoloads**

**Step 5: Commit**

---

## Phase 2: Physics Sandbox (Milestone 1)

### Task 2.1: Board Scene (Physics World) — VO-002

**Files:**
- Create: `res://scenes/game/Board.tscn`
- Modify: `res://scripts/autoloads/RunState.gd` (add pocket tracking)

**Step 1: Create Board.tscn**

```
Node2D (Board)
├── ColorRect (Background) - Deep Void #0A0A1A
├── StaticBody2D (Walls)
│   ├── CollisionPolygon2D (Left wall)
│   ├── CollisionPolygon2D (Right wall)
│   ├── CollisionPolygon2D (Top)
│   └── CollisionPolygon2D (Bottom barrier)
├── Node2D (Pockets)
│   ├── Area2D (Pocket_Damage_1) + CollisionShape2D
│   ├── Area2D (Pocket_Damage_2) + CollisionShape2D
│   ├── Area2D (Pocket_Heal_1) + CollisionShape2D
│   ├── Area2D (Pocket_Heal_2) + CollisionShape2D
│   ├── Area2D (Pocket_Gold_1) + CollisionShape2D
│   ├── Area2D (Pocket_Gold_2) + CollisionShape2D
│   ├── Area2D (Pocket_Void) + CollisionShape2D
│   └── Area2D (Pocket_Chaos) + CollisionShape2D
└── Node2D (PegContainer) - holds player pegs
```

**Step 2: Configure physics**
- Board dimensions: 600x900px logical space
- Walls: StaticBody2D with collision shapes
- 8 pockets at bottom with Area2D detectors

**Step 3: Verify ball stays in bounds when dropped**

**Step 4: Commit**

---

### Task 2.2: Ball Physics — VO-003

**Files:**
- Create: `res://scenes/game/Ball.tscn`
- Create: `res://scripts/game/Ball.gd`

**Step 1: Create Ball.tscn**

```
RigidBody2D (Ball) - group: "ball"
├── CollisionShape2D (CircleShape2D, radius: 12px)
├── Sprite2D (Ball sprite - pearlescent white)
└── GPUParticles2D (Trail particles)
```

**Step 2: Configure RigidBody2D**
- Mass: 1.0
- Gravity scale: 1.4
- Linear damp: 0.05
- Continuous CD: Cast Ray

**Step 3: Create Ball.gd**

```gdscript
extends RigidBody2D

func _ready() -> void:
	add_to_group("ball")

func _exit_tree() -> void:
	if is_instance_valid(self):
		EventBus.ball_lost.emit(self)
```

**Step 4: Connect pocket detection in Board.tscn**
- On Area2D body_entered: emit `EventBus.ball_entered_pocket`

**Step 5: Test ball drops from top, hits pockets, signals fire**

**Step 6: Commit**

---

### Task 2.3: Base Peg + All 8 Peg Types — VO-004

**Files:**
- Create: `res://scenes/game/pegs/BasePeg.tscn`
- Create: `res://scripts/game/pegs/BasePeg.gd`
- Create: `res://data/pegs/peg_definitions.json`
- Create: `res://scenes/game/pegs/StonePeg.tscn`
- Create: `res://scenes/game/pegs/BonePeg.tscn`
- Create: `res://scenes/game/pegs/FungalPeg.tscn`
- Create: `res://scenes/game/pegs/EmberPeg.tscn`
- Create: `res://scenes/game/pegs/EyePeg.tscn`
- Create: `res://scenes/game/pegs/HeartPeg.tscn`
- Create: `res://scenes/game/pegs/OraclePeg.tscn`
- Create: `res://scenes/game/pegs/VoidRiftPeg.tscn`

**Step 1: Create peg_definitions.json**

```json
{
  "stone": {
    "restitution": 0.6,
    "friction": 0.1,
    "tags": ["foundation"],
    "special": null
  },
  "bone": {
    "restitution": 0.5,
    "friction": 0.05,
    "tags": ["death"],
    "special": null
  },
  "fungal": {
    "restitution": 0.4,
    "friction": 0.45,
    "tags": ["growth", "death"],
    "special": "spawns_sprout"
  },
  "ember": {
    "restitution": 0.9,
    "friction": 0.05,
    "tags": ["fire"],
    "special": "ignites_adjacent"
  },
  "eye": {
    "restitution": 0.6,
    "friction": 0.1,
    "tags": ["void"],
    "special": "reveals_pockets"
  },
  "heart": {
    "restitution": 0.7,
    "friction": 0.15,
    "tags": ["blood"],
    "special": "heals_stability"
  },
  "oracle": {
    "restitution": 0.6,
    "friction": 0.1,
    "tags": ["all"],
    "special": "splits_ball"
  },
  "void_rift": {
    "restitution": 0.0,
    "friction": 0.0,
    "tags": ["void"],
    "special": "teleports_ball"
  }
}
```

**Step 2: Create BasePeg.gd**

```gdscript
extends StaticBody2D

@export var peg_type: String = "stone"
@export var peg_state: String = "dormant"
@export var hit_count: int = 0

var physics_material: PhysicsMaterial

func _ready() -> void:
	load_peg_definition()
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func load_peg_definition() -> void:
	var json = FileAccess.open("res://data/pegs/peg_definitions.json", FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text())
	var def = data[peg_type]
	physics_material = PhysicsMaterial.new()
	physics_material.bounce = def.restitution
	physics_material.friction = def.friction
	self.physics_material = physics_material

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		hit_count += 1
		EventBus.peg_hit.emit(self, body)
		_try_mutate()

func _try_mutate() -> void:
	# Will be implemented by MutationEngine
	pass

func _update_visual() -> void:
	# Will update shader uniforms
	pass
```

**Step 3: Create one .tscn per peg type extending BasePeg**
- Placeholder ColorRect for now (art comes later)
- Set appropriate collision shape (radius: 16px)

**Step 4: Test all 8 pegs instantiable, correct restitution/friction**

**Step 5: Commit**

---

### Task 2.4: Ball Spawner — VO-005

**Files:**
- Create: `res://scripts/game/BallSpawner.gd`
- Modify: `res://scenes/game/Board.tscn` (add spawner node)

**Step 1: Create BallSpawner.gd**

```gdscript
extends Node2D

@export var ball_scene: PackedScene

var can_spawn: bool = true
var current_angle: float = 0.0
var aim_line: Line2D

func _ready() -> void:
	aim_line = Line2D.new()
	aim_line.width = 2.0
	aim_line.default_color = Color(0.8, 0.8, 1.0, 0.5)
	add_child(aim_line)

func _process(_delta: float) -> void:
	_update_aim_line()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_spawn_ball()

func _update_aim_line() -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	current_angle = direction.angle()

	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(direction * 200)

func _spawn_ball() -> void:
	if RunState.ball_count <= 0:
		return

	var ball = ball_scene.instantiate()
	ball.position = global_position
	ball.linear_velocity = Vector2(cos(current_angle), sin(current_angle)) * 500
	get_parent().add_child(ball)
	RunState.ball_count -= 1
```

**Step 2: Add to Board.tscn at top**
- Configure ball_scene in inspector

**Step 3: Test click launches ball, aim line updates**

**Step 4: Commit**

---

### Task 2.5: Physics Debug Overlay — VO-006

**Files:**
- Create: `res://scripts/systems/PhysicsDebug.gd`
- Modify: `res://scenes/game/Board.tscn`

**Step 1: Create PhysicsDebug.gd**

```gdscript
extends Node

var debug_labels: Array = []
var show_debug: bool = false

func _ready() -> void:
	Input.key_pressed.connect(_on_key_pressed)

func _on_key_pressed(event: InputEvent) -> void:
	if event.keycode == KEY_F1:
		show_debug = not show_debug
		_toggle_debug_overlay()

func _toggle_debug_overlay() -> void:
	# Toggle collision shape visibility on all physics objects
	# Show velocity vectors on balls
	# Show hit_count labels on pegs
	pass
```

**Step 2: Test F1 toggles overlay, peg hits print to console**

**Step 3: Commit**

---

## Phase 3: Core Systems (Milestone 2)

### Task 3.1: Peg State Shader — VO-007

**Files:**
- Create: `res://shaders/peg_state.gdshader`

**Step 1: Create peg_state.gdshader**

```glsl
shader_type canvas_item;

uniform float corruption_level : hint_range(0.0, 1.0) = 0.5;
uniform float mutation_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float void_factor : hint_range(0.0, 1.0) = 0.0;

uniform vec4 blessed_color : source_color = vec4(0.788, 0.659, 0.298, 1.0);
uniform vec4 neutral_color : vec4(0.91, 0.894, 0.941, 1.0);
uniform vec4 cursed_color : vec4(0.549, 0.118, 0.118, 1.0);
uniform vec4 mutant_color : vec4(0.118, 0.369, 0.165, 1.0);

void fragment() {
	vec4 base_color;

	if (corruption_level < 0.5) {
		base_color = mix(blessed_color, neutral_color, corruption_level * 2.0);
	} else {
		base_color = mix(neutral_color, cursed_color, (corruption_level - 0.5) * 2.0);
	}

	// Add mutation pulse effect
	float pulse = sin(TIME * 3.0) * 0.5 + 0.5;
	base_color = mix(base_color, mutant_color, mutation_pulse * pulse);

	// Add void stars
	if (void_factor > 0.0) {
		// Star field effect
	}

	COLOR = base_color;
}
```

**Step 2: Apply to pegs via ShaderMaterial**

**Step 3: Test manually tweaking uniforms shifts appearance**

**Step 4: Commit**

---

### Task 3.2: Mutation Engine Integration — VO-008

**Files:**
- Modify: `res://scripts/autoloads/MutationEngine.gd`

**Step 1: Implement MutationEngine.gd**

```gdscript
extends Node

const MUTATION_THRESHOLD = 5
const MUTATION_CHANCE = 0.15

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, _ball: Node) -> void:
	if peg.hit_count >= MUTATION_THRESHOLD:
		if randf() < MUTATION_CHANCE:
			_mutate_peg(peg)

func _mutate_peg(peg: Node) -> void:
	var old_state = peg.peg_state
	var new_state = ""

	match peg.peg_state:
		"dormant":
			new_state = "blessed" if randf() < 0.5 else "cursed"
		"blessed":
			new_state = "mutant" if randf() < 0.3 else "blessed"
		"cursed":
			new_state = "mutant" if randf() < 0.4 else "cursed"
		"mutant":
			new_state = "void_touched" if randf() < 0.1 else "mutant"

	if new_state != "" and new_state != old_state:
		peg.peg_state = new_state
		peg._update_visual()
		EventBus.peg_state_changed.emit(peg, old_state, new_state)
```

**Step 2: Test hitting a peg 5+ times causes visible mutation**

**Step 3: Commit**

---

### Task 3.3: Synergy Checker Integration — VO-009

**Files:**
- Create: `res://data/synergies/synergy_definitions.json`
- Modify: `res://scripts/autoloads/SynergyChecker.gd`

**Step 1: Create synergy_definitions.json**

```json
{
  "necrotic_bloom": {
    "tags": ["death", "growth"],
    "min_pegs": 3,
    "tier1_effect": "Rot pegs deal 3 dmg on contact",
    "tier2_effect": "All pegs regen 1 Stability/drop",
    "curse_risk": "Rot spreads 2x faster"
  },
  "cursed_flame": {
    "tags": ["fire", "cursed"],
    "min_pegs": 3,
    "tier1_effect": "Burning pegs corrupt adjacent on ignite",
    "tier2_effect": "Ball speed +20%, double damage",
    "curse_risk": "Board takes 5 dmg/drop"
  },
  "void_choir": {
    "tags": ["void"],
    "min_pegs": 3,
    "tier1_effect": "Every 5th ball becomes Void Ball",
    "tier2_effect": "Void Balls open extra pocket slot",
    "curse_risk": "Void consumes 1 Blessed peg/run"
  },
  "bleeding_arch": {
    "tags": ["blood", "foundation"],
    "min_pegs": 3,
    "tier1_effect": "Stone pegs heal 1 Stability on contact",
    "tier2_effect": "Board gains Regen 2 passive",
    "curse_risk": "Heart pegs slowly rot"
  },
  "profane_eye": {
    "tags": ["void", "death"],
    "min_pegs": 3,
    "tier1_effect": "Eye pegs reveal enemy next move",
    "tier2_effect": "Bone pegs double dmg vs revealed",
    "curse_risk": "Eye pegs blind randomly"
  }
}
```

**Step 2: Implement SynergyChecker.gd**

```gdscript
extends Node

var active_synergies: Dictionary = {}

func _ready() -> void:
	EventBus.peg_state_changed.connect(_on_peg_state_changed)
	EventBus.peg_spawned.connect(_on_peg_spawned)

func _on_peg_state_changed(peg: Node, _old: String, _new: String) -> void:
	_recheck_synergies()

func _on_peg_spawned(peg: Node) -> void:
	_recheck_synergies()

func _recheck_synergies() -> void:
	# Count tags from all pegs
	# Check each synergy threshold
	# Emit signals for activate/broken/scaled
	pass
```

**Step 3: Test placing 3 Fungal + 3 Bone pegs triggers necrotic_bloom**

**Step 4: Commit**

---

### Task 3.4: Special Peg Behaviors — VO-010

**Files:**
- Modify: `res://scripts/game/pegs/BasePeg.gd`
- Create: `res://scripts/game/pegs/OraclePeg.gd`
- Create: `res://scripts/game/pegs/VoidRiftPeg.gd`
- Create: `res://scripts/game/pegs/EmberPeg.gd`
- Create: `res://scripts/game/pegs/FungalPeg.gd`

**Step 1: Implement Oracle Peg**
- On hit: spawn 2 additional balls at slight angle offset

**Step 2: Implement Void Rift Peg**
- On hit: remove ball from physics, add +10 gold via RunState

**Step 3: Implement Ember Peg**
- On hit: iterate adjacent pegs, shift toward "cursed" by 0.1

**Step 4: Implement Fungal Peg**
- After every 3 drops: check adjacent empty slots, 25% chance spawn Sprout

**Step 5: Test each special behavior**

**Step 6: Commit**

---

### Task 3.5: Corruption Spread Shader — VO-011

**Files:**
- Create: `res://shaders/corruption_spread.gdshader`

**Step 1: Create corruption_spread.gdshader**
- Accepts sampler2D corruption_map (64x64)
- Bleeds/blurs corruption across background

**Step 2: Connect to EventBus.peg_state_changed**

**Step 3: Test cursing a peg spreads ink across background**

**Step 4: Commit**

---

### Task 3.6: Ball Trail Effect — VO-012

**Files:**
- Create: `res://shaders/ball_trail.gdshader`
- Modify: `res://scripts/game/Ball.gd`

**Step 1: Create ball_trail.gdshader**

**Step 2: Add Line2D trail to Ball**

**Step 3: Test ball leaves visible fading trail**

**Step 4: Commit**

---

## Phase 4: Single Encounter (Milestone 3)

### Task 4.1: Drop/Result Phase Loop — VO-013

**Files:**
- Create: `res://scripts/systems/PhaseManager.gd`

**Step 1: Implement PhaseManager.gd**
- Drop Phase: launch N balls, wait for all to settle
- Result Phase: tally pocket results
- Board Phase: show draft UI stub

**Step 2: Test full drop → result → next drop loop runs**

**Step 3: Commit**

---

### Task 4.2: Corruptor Enemy — VO-014

**Files:**
- Create: `res://scenes/game/enemies/Corruptor.tscn`
- Create: `res://scripts/game/enemies/Corruptor.gd`
- Create: `res://data/enemies/corruptor.json`

**Step 1: Create enemy data**

```json
{
  "id": "corruptor",
  "name": "Corruptor",
  "hp": 80,
  "action": "shift_random_blessed_to_cursed"
}
```

**Step 2: Create Corruptor.gd**
- Enemy panel UI: HP bar, name, intent display
- Each turn: pick 1 random Blessed peg → Cursed (or Dormant if no Blessed)
- On death: emit EventBus.enemy_defeated

**Step 3: Test full combat loop**

**Step 4: Commit**

---

### Task 4.3: Stability System UI — VO-015

**Files:**
- Create: `res://scenes/game/BoardUI.tscn`
- Create: `res://scripts/game/BoardUI.gd`

**Step 1: Create stability bar (ColorRect)**
- Fills left to right
- Gold → red as depletes
- Tick down 10 stability on enemy action

**Step 2: Test stability depletes, 0 triggers game over**

**Step 3: Commit**

---

### Task 4.4: Ghost Board Save on Death — VO-016

**Files:**
- Modify: `res://scripts/autoloads/GhostBoardManager.gd`

**Step 1: Implement GhostBoardManager.gd**
- save_ghost(board_state)
- load_ghost(index)
- get_active_ghost()

**Step 2: Wire to EventBus.run_ended**

**Step 3: Test death saves ghost, restart loads ghost**

**Step 4: Commit**

---

## Phase 5: Ghost Board Encounter (Milestone 4)

### Task 5.1: Ghost Board Encounter Scene — VO-017

**Files:**
- Create: `res://scenes/game/encounters/GhostBoardEncounter.tscn`
- Create: `res://scripts/game/encounters/GhostBoardEncounter.gd`

**Step 1: Load ghost board layout**
- Render as semi-transparent display
- Implement ghost behavior based on board composition

**Step 2: Test ghost encounter spawns with correct behavior**

**Step 3: Commit**

---

### Task 5.2: Ghost Board Assignment — VO-018

**Files:**
- Modify: `res://scripts/autoloads/GhostBoardManager.gd`

**Step 1: Implement assign_ghost_for_run(run_seed)**
- Seeded random pick from saved ghosts
- Place at deterministic position in Zone 2

**Step 2: Test ghost appears in same position with same seed**

**Step 3: Commit**

---

## Phase 6: Map & Full Run Loop (Milestone 5)

### Task 6.1: Run Map (DAG Generator) — VO-019

**Files:**
- Create: `res://scripts/systems/MapGenerator.gd`
- Create: `res://scenes/map/RunMap.tscn`
- Create: `res://scenes/map/MapNode.tscn`

**Step 1: Implement MapGenerator.gd**
- Generates 3-zone DAG, 8-10 nodes per zone
- Node types: Combat(40%), Elite(15%), Event(20%), Shop(10%), Rest(10%), Boss
- Weight by RunState board tags

**Step 2: Test map generates, player navigates zone 1**

**Step 3: Commit**

---

### Task 6.2: Draft System — VO-020

**Files:**
- Create: `res://scripts/systems/DraftSystem.gd`
- Create: `res://scenes/game/ui/DraftUI.tscn`

**Step 1: Implement DraftSystem.gd**
- Show 3 randomly drawn pegs from tier-weighted pool
- Player clicks to select
- Seeded from run_seed + encounter_index

**Step 2: Test win fight, see 3 choices, place selection**

**Step 3: Commit**

---

### Task 6.3: Shop — VO-021

**Files:**
- Create: `res://scenes/game/ui/ShopUI.tscn`
- Create: `res://scripts/systems/ShopSystem.gd`

**Step 1: Implement ShopSystem.gd**
- Appears every ~4 nodes
- Offers: 3 pegs, 1 relic, 3 services
- Costs in Gold

**Step 2: Test enter shop, buy peg**

**Step 3: Commit**

---

### Task 6.4: Remaining Enemy Types — VO-022

**Files:**
- Create: `res://scenes/game/enemies/Wrecker.tscn`
- Create: `res://scenes/game/enemies/Spawner.tscn`

**Step 1: Implement Wrecker**
- Shatters 1 peg per turn

**Step 2: Implement Spawner**
- Drops enemy balls with inverse effect

**Step 3: Test both enemies behave distinctly**

**Step 4: Commit**

---

### Task 6.5: Zone 1 Boss — The Gardener — VO-023

**Files:**
- Create: `res://scenes/game/enemies/Gardener.tscn`
- Create: `res://scripts/game/enemies/Gardener.gd`

**Step 1: Implement multi-phase boss**
- Phase 1: Converts Blessed → Dormant each turn
- Phase 2 (below 50% HP): Places 2 Thorn pegs
- HP: 150
- Victory: zone 2 unlocks

**Step 2: Test full Gardener fight, both phases**

**Step 3: Commit**

---

## Phase 7: Full Game (Milestone 6)

### Task 7.1: Zone 2 + Architect of Ruin Boss — VO-024

### Task 7.2: Zone 3 + Final Oracle Boss — VO-025

### Task 7.3: All 5 Synergy Effects — VO-026

### Task 7.4: Meta-Progression — VO-027

### Task 7.5: Oracle Classes — VO-028

### Task 7.6: Run History Screen — VO-029

---

## Phase 8: Polish & Export (Milestone 7)

### Task 8.1: Full Shader Pass — VO-030

### Task 8.2: Audio: Per-Peg Tone System — VO-031

### Task 8.3: Audio: Ambient Layering — VO-032

### Task 8.4: Main Menu + UI Polish — VO-033

### Task 8.5: Web Export Test — VO-034

### Task 8.6: Mobile Touch Input — VO-035

---

## Phase 9: Steam (Milestone 8)

### Task 9.1: Windows + macOS Builds — VO-036

### Task 9.2: GodotSteam Integration — VO-037

### Task 9.3: Steam Page Assets — VO-038

---

## Summary

| Phase | Milestone | Key Deliverables | Priority |
|-------|-----------|------------------|----------|
| 1 | Project Foundation | Godot project, 6 AutoLoads | Critical |
| 2 | Physics Sandbox | Board, Ball, Pegs, Spawner, Debug | High |
| 3 | Core Systems | Shaders, Mutation, Synergies, Special pegs | High |
| 4 | Single Encounter | Phase loop, Corruptor, Stability, Ghost save | High |
| 5 | Ghost Board | Ghost encounter scene, assignment | Medium |
| 6 | Map & Run | Map, Draft, Shop, 2 enemies, Gardener boss | Medium |
| 7 | Full Game | Zones 2-3, bosses, synergies, meta | Medium |
| 8 | Polish | Audio, shaders, export | Low |
| 9 | Steam | Builds, achievements | Low |
