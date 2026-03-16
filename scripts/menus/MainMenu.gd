## MainMenu - Entry point for the game

extends Control

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	RunState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/game/Board.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
