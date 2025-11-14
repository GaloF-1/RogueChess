extends Node

@onready var start_screen: Control = $StartScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var game_scene: Node2D = $Game
@onready var game_manager: GameManager = $Game/GameManager

func _ready() -> void:
	start_screen.start_game_requested.connect(_on_start_game_requested)
	game_over_screen.play_again_requested.connect(_on_play_again_requested)
	game_manager.game_over.connect(_on_game_over)

	# Initially, only the start screen is visible
	game_scene.visible = false
	game_over_screen.visible = false
	start_screen.visible = true

func _on_start_game_requested() -> void:
	start_new_game()

func _on_play_again_requested() -> void:
	start_new_game()

func _on_game_over() -> void:
	game_scene.visible = false
	game_over_screen.visible = true

func start_new_game() -> void:
	start_screen.visible = false
	game_over_screen.visible = false
	game_scene.visible = true
	game_manager.start_new_run()
