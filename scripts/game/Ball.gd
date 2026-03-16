## Ball - The physics-driven ball that bounces through the board

extends RigidBody2D

# Ball state properties
var is_blessed: bool = false
var is_cursed: bool = false
var is_rot: bool = false
var is_void: bool = false

# Trail settings
const TRAIL_LENGTH: int = 20
var trail_positions: Array[Vector2] = []

@onready var trail: Line2D = $Trail

# Physics parameters (from tech spec)
const GRAVITY_SCALE: float = 1.4
const LINEAR_DAMP: float = 0.05
const MAX_VELOCITY: float = 4000.0

func _ready() -> void:
	# Add to ball group for collision detection
	add_to_group("ball")

	# Setup continuous collision detection
	continuous_cd = PhysicsServer2D.CCD_MODE_CAST_RAY

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Initialize trail
	_init_trail()

func _physics_process(_delta: float) -> void:
	# Clamp velocity to prevent tunneling
	var vel = linear_velocity
	var speed = vel.length()
	if speed > MAX_VELOCITY:
		linear_velocity = vel.normalized() * MAX_VELOCITY

	# Update trail
	_update_trail()

	# Check if ball has fallen off screen
	_check_ball_lost()

func _init_trail() -> void:
	if trail:
		trail.clear_points()
		for i in range(TRAIL_LENGTH):
			trail.add_point(position)

func _update_trail() -> void:
	if trail and trail.get_point_count() > 0:
		# Shift points back
		for i in range(trail.get_point_count() - 1, 0, -1):
			trail.set_point_position(i, trail.get_point_position(i - 1))
		# Add new position at front
		trail.set_point_position(0, position)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("peg"):
		# Emit peg hit event
		EventBus.emit_signal("peg_hit", body, self)

func _check_ball_lost() -> void:
	# Check if ball has fallen below the board
	if position.y > 950:
		EventBus.emit_signal("ball_lost", self)
		queue_free()

func set_blessed(value: bool) -> void:
	is_blessed = value
	_update_visual()

func set_cursed(value: bool) -> void:
	is_cursed = value
	_update_visual()

func set_rot(value: bool) -> void:
	is_rot = value
	_update_visual()

func set_void(value: bool) -> void:
	is_void = value
	_update_visual()

func _update_visual() -> void:
	# Update ball color based on state
	# In production, would change sprite/shader
	pass

func apply_impulse_towards_target(target: Vector2, force: float) -> void:
	var direction = (target - position).normalized()
	apply_central_impulse(direction * force)

func split() -> void:
	# Oracle peg special - split into 3 balls
	# In production, would create 2 additional balls
	pass
