**VOID ORACLE — Implementation Plan**

*Gap Analysis: Current State vs. Specification*

---

## Executive Summary

**Current State**: PHASE 1 & 2 IN PROGRESS - Godot project initialized with core scenes, all 8 peg types, and physics systems.
- `res://` directory structure created
- project.godot file exists with all AutoLoads configured
- Core scenes: Board.tscn, Ball.tscn, BasePeg.tscn, 8 peg type scenes, MainMenu.tscn
- AutoLoads: EventBus, RunState, GhostBoardManager, SynergyChecker, AudioManager, MutationEngine
- PhysicsDebug overlay for development

**Gap Analysis**:
| Spec Section | Status | Priority |
|---------------|--------|----------|
| Phase 1: Project Foundation | COMPLETE | CRITICAL |
| Phase 2: Physics Sandbox | IN PROGRESS | HIGH |
| Phase 3: Core Systems | NOT STARTED | HIGH |
| Phase 4: Single Encounter | NOT STARTED | HIGH |
| Phase 5-9 | NOT STARTED | MEDIUM-LOW |

---

## Phase 1: Project Foundation (CRITICAL)

### Task 1.1: Initialize Godot Project Structure

**Files to create:**
- `res://project.godot` - Godot project file
- `res://.gitignore` - Git ignore for Godot
- `res://scenes/game/` - Game scenes directory
- `res://scenes/menus/` - Menu scenes directory
- `res://scenes/map/` - Map scenes directory
- `res://scripts/autoloads/` - AutoLoad singletons
- `res://scripts/systems/` - Game systems
- `res://scripts/pegs/` - Peg scripts
- `res://scripts/game/` - Game scripts
- `res://scripts/enemies/` - Enemy scripts
- `res://data/pegs/` - Peg JSON definitions
- `res://data/synergies/` - Synergy definitions
- `res://data/enemies/` - Enemy definitions
- `res://data/events/` - Event definitions
- `res://shaders/` - Shader files
- `res://assets/audio/` - Audio directory
- `res://assets/textures/` - Textures directory

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

---

### Task 1.2: Create AutoLoad Singletons (Skeleton)

**Files to create:**
- `res://scripts/autoloads/EventBus.gd` - Signal hub
- `res://scripts/autoloads/RunState.gd` - Run state
- `res://scripts/autoloads/GhostBoardManager.gd` - Ghost persistence
- `res://scripts/autoloads/SynergyChecker.gd` - Synergy detection
- `res://scripts/autoloads/AudioManager.gd` - Audio system
- `res://scripts/autoloads/MutationEngine.gd` - Mutation logic

**EventBus.gd signals:**
```gdscript
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

**RunState.gd variables:**
```gdscript
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
```

---

## Phase 2: Physics Sandbox (HIGH PRIORITY)

### Task 2.1: Board Scene (Physics World) — VO-002

**Files:**
- Create: `res://scenes/game/Board.tscn`
- Create: `res://scripts/game/Board.gd`

**Scene structure:**
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

**Board dimensions**: 600x900px logical space

---

### Task 2.2: Ball Physics — VO-003

**Files:**
- Create: `res://scenes/game/Ball.tscn`
- Create: `res://scripts/game/Ball.gd`

**RigidBody2D settings:**
- Mass: 1.0
- Gravity scale: 1.4
- Linear damp: 0.05
- Continuous CD: Cast Ray
- CollisionShape2D: CircleShape2D, radius 12px

---

### Task 2.3: Base Peg + All 8 Peg Types — VO-004

**Files:**
- Create: `res://scenes/game/pegs/BasePeg.tscn`
- Create: `res://scripts/game/pegs/BasePeg.gd`
- Create: `res://data/pegs/peg_definitions.json`
- Create: 8 peg type scenes (Stone, Bone, Fungal, Ember, Eye, Heart, Oracle, VoidRift)

**peg_definitions.json structure:**
```json
{
  "stone": { "restitution": 0.6, "friction": 0.1, "tags": ["foundation"], "special": null },
  "bone": { "restitution": 0.5, "friction": 0.05, "tags": ["death"], "special": null },
  "fungal": { "restitution": 0.4, "friction": 0.45, "tags": ["growth", "death"], "special": "spawns_sprout" },
  "ember": { "restitution": 0.9, "friction": 0.05, "tags": ["fire"], "special": "ignites_adjacent" },
  "eye": { "restitution": 0.6, "friction": 0.1, "tags": ["void"], "special": "reveals_pockets" },
  "heart": { "restitution": 0.7, "friction": 0.15, "tags": ["blood"], "special": "heals_stability" },
  "oracle": { "restitution": 0.6, "friction": 0.1, "tags": ["all"], "special": "splits_ball" },
  "void_rift": { "restitution": 0.0, "friction": 0.0, "tags": ["void"], "special": "teleports_ball" }
}
```

---

### Task 2.4: Ball Spawner — VO-005

**Files:**
- Create: `res://scripts/game/BallSpawner.gd`

**Features:**
- Aim line: Line2D showing projected launch angle
- Click/tap to launch ball
- Ball count limited by RunState.ball_count

---

### Task 2.5: Physics Debug Overlay — VO-006

**Files:**
- Create: `res://scripts/systems/PhysicsDebug.gd`

**Features:**
- F1 key toggle
- Shows collider shapes, ball velocity vectors, peg hit_count labels

---

## Phase 3: Core Systems (HIGH PRIORITY)

### Task 3.1: Peg State Shader — VO-007
### Task 3.2: Mutation Engine Integration — VO-008
### Task 3.3: Synergy Checker Integration — VO-009
### Task 3.4: Special Peg Behaviors — VO-010
### Task 3.5: Corruption Spread Shader — VO-011
### Task 3.6: Ball Trail Effect — VO-012

---

## Phase 4: Single Encounter (HIGH PRIORITY)

### Task 4.1: Drop/Result Phase Loop — VO-013
### Task 4.2: Corruptor Enemy — VO-014
### Task 4.3: Stability System UI — VO-015
### Task 4.4: Ghost Board Save on Death — VO-016

---

## Phase 5-9: Future Phases

### Phase 5: Ghost Board Encounter
### Phase 6: Map & Full Run Loop
### Phase 7: Full Game (Zones 2-3, bosses)
### Phase 8: Polish & Web Export
### Phase 9: Steam

---

## Prioritized Task List

| Priority | Task | ID | Phase |
|----------|------|-----|-------|
| 1 | Initialize Godot project structure | 1.1 | 1 |
| 2 | Create AutoLoad singletons (skeleton) | 1.2 | 1 |
| 3 | Board scene (physics world) | 2.1 | 2 |
| 4 | Ball physics | 2.2 | 2 |
| 5 | Base peg + 8 peg types | 2.3 | 2 |
| 6 | Ball spawner | 2.4 | 2 |
| 7 | Physics debug overlay | 2.5 | 2 |
| 8 | Peg state shader | 3.1 | 3 |
| 9 | Mutation engine | 3.2 | 3 |
| 10 | Synergy checker | 3.3 | 3 |
| 11 | Special peg behaviors | 3.4 | 3 |
| 12 | Corruption spread shader | 3.5 | 3 |
| 13 | Ball trail effect | 3.6 | 3 |
| 14 | Phase loop | 4.1 | 4 |
| 15 | Corruptor enemy | 4.2 | 4 |
| 16 | Stability UI | 4.3 | 4 |
| 17 | Ghost save on death | 4.4 | 4 |
| 18 | Ghost board encounter | 5.1 | 5 |
| 19 | Ghost assignment | 5.2 | 5 |
| 20 | Run map (DAG) | 6.1 | 6 |
| 21 | Draft system | 6.2 | 6 |
| 22 | Shop | 6.3 | 6 |
| 23 | Wrecker/Spawner enemies | 6.4 | 6 |
| 24 | Zone 1 Boss (Gardener) | 6.5 | 6 |
| 25 | Zone 2 + Architect Boss | 7.1 | 7 |
| 26 | Zone 3 + Final Oracle | 7.2 | 7 |
| 27 | All synergy effects | 7.3 | 7 |
| 28 | Meta-progression | 7.4 | 7 |
| 29 | Oracle classes | 7.5 | 7 |
| 30 | Run history screen | 7.6 | 7 |
| 31 | Full shader pass | 8.1 | 8 |
| 32 | Per-peg audio tones | 8.2 | 8 |
| 33 | Ambient layering | 8.3 | 8 |
| 34 | Main menu + UI polish | 8.4 | 8 |
| 35 | Web export test | 8.5 | 8 |
| 36 | Mobile touch input | 8.6 | 8 |
| 37 | Windows + macOS builds | 9.1 | 9 |
| 38 | GodotSteam integration | 9.2 | 9 |
| 39 | Steam page assets | 9.3 | 9 |

---

## Immediate Next Steps

1. **Create project.godot** with all AutoLoad configurations
2. **Create skeleton AutoLoads** (EventBus, RunState, GhostBoardManager, SynergyChecker, AudioManager, MutationEngine)
3. **Create Board.tscn** with physics boundaries and pockets
4. **Create Ball.tscn** with RigidBody2D physics
5. **Create BasePeg.tscn** and peg_definitions.json
6. **Test basic physics** - ball drops, hits pegs, enters pockets

---

*Last Updated: 2026-03-16*
*Status: GREENFIELD - No code exists*
