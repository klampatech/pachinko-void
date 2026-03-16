## PhysicsDebug - Debug overlay showing collider shapes, velocities, and hit counts

extends Node

var enabled: bool = false

@onready var debug_canvas: CanvasLayer = $DebugCanvas
@onready var debug_labels: Node = $DebugCanvas/Labels

func _ready() -> void:
	_create_debug_layer()
	EventBus.run_started.connect(_on_run_started)

func _create_debug_layer() -> void:
	debug_canvas = CanvasLayer.new()
	debug_canvas.name = "DebugCanvas"
	debug_canvas.layer = 100
	debug_canvas.visible = enabled
	add_child(debug_canvas)

	var labels = Node2D.new()
	labels.name = "Labels"
	debug_canvas.add_child(labels)
	debug_labels = labels

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):  # F1 key
		_toggle_debug()

func _toggle_debug() -> void:
	enabled = not enabled
	if debug_canvas:
		debug_canvas.visible = enabled

func _process(_delta: float) -> void:
	if not enabled:
		return

	_update_ball_velocities()
	_update_peg_hit_counts()

func _update_ball_velocities() -> void:
	# Clear existing labels
	if not debug_labels:
		return

	for child in debug_labels.get_children():
		child.queue_free()

	# Draw velocity vectors for all balls
	var balls = get_tree().get_nodes_in_group("ball")
	for ball in balls:
		var velocity_label = Label.new()
		velocity_label.text = "%.0f" % ball.linear_velocity.length()
		velocity_label.position = ball.position + Vector2(15, -20)
		velocity_label.add_theme_font_size_override("font_size", 10)
		velocity_label.add_theme_color_override("font_color", Color.CYAN)
		debug_labels.add_child(velocity_label)

		# Draw velocity line
		var line = Line2D.new()
		line.add_point(ball.position)
		line.add_point(ball.position + ball.linear_velocity.normalized() * 50)
		line.width = 2
		line.default_color = Color.CYAN
		debug_labels.add_child(line)

func _update_peg_hit_counts() -> void:
	# Show hit counts on pegs
	var pegs = get_tree().get_nodes_in_group("peg")
	for peg in pegs:
		if peg.has_method("get_hit_count"):
			var hit_count = peg.get("hit_count", 0)
			if hit_count > 0:
				var label = Label.new()
				label.text = str(hit_count)
				label.position = peg.position + Vector2(10, -10)
				label.add_theme_font_size_override("font_size", 8)
				label.add_theme_color_override("font_color", Color.YELLOW)
				debug_labels.add_child(label)

func _on_run_started() -> void:
	enabled = false
	if debug_canvas:
		debug_canvas.visible = false
