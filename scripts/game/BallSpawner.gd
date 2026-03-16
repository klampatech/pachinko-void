## BallSpawner - Handles ball launching mechanics

extends Node2D

# Launch parameters
const MIN_ANGLE: float = -60.0  # degrees from vertical
const MAX_ANGLE: float = 60.0
const LAUNCH_FORCE: float = 800.0

var current_angle: float = 0.0
var is_aiming: bool = false
var balls_remaining: int = 1

@onready var aim_line: Line2D = $AimLine
@onready var ball_scene: PackedScene = preload("res://scenes/game/Ball.tscn")

func _ready() -> void:
	balls_remaining = RunState.ball_count

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_aiming()
			else:
				launch_ball()
	elif event is InputEventMouseMotion and is_aiming:
		update_aim_angle(event.position)

func _process(_delta: float) -> void:
	if is_aiming:
		queue_redraw()

func start_aiming() -> void:
	if balls_remaining <= 0:
		return
	is_aiming = true

func update_aim_angle(mouse_pos: Vector2) -> void:
	# Calculate angle from spawner to mouse
	var local_pos = get_global_mouse_position() - global_position
	var angle_rad = local_pos.angle()
	var angle_deg = rad_to_deg(angle_rad)

	# Clamp to valid range
	current_angle = clampf(angle_deg, MIN_ANGLE, MAX_ANGLE)

func launch_ball() -> void:
	if not is_aiming or balls_remaining <= 0:
		is_aiming = false
		return

	is_aiming = false
	balls_remaining -= 1

	var ball = ball_scene.instantiate()

	# Position at spawner
	ball.position = global_position

	# Calculate launch velocity
	var angle_rad = deg_to_rad(current_angle)
	var direction = Vector2(sin(angle_rad), cos(angle_rad))
	ball.linear_velocity = direction * LAUNCH_FORCE

	# Add to parent
	get_parent().add_child(ball)

	# Emit drop started
	EventBus.emit_signal("drop_phase_started")

func _draw() -> void:
	if is_aiming:
		# Draw aim line
		var angle_rad = deg_to_rad(current_angle)
		var end_point = Vector2(
			sin(angle_rad) * 200,
			cos(angle_rad) * 200
		)
		draw_line(Vector2.ZERO, end_point, Color(1, 1, 1, 0.5), 2.0)

func reset_balls() -> void:
	balls_remaining = RunState.ball_count

func get_balls_remaining() -> int:
	return balls_remaining
