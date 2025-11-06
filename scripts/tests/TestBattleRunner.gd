extends Node2D

const BATTLE_SCENE = preload("res://scenes/chess/Battle.tscn")
const PAWN_SCENE = preload("res://scenes/chess/Pawn.tscn")
const PAWN_BLUEPRINT = preload("res://assets/blueprints/pawn_blueprint.tres")

func _ready():
	# Ensure GameManager is available
	var game_manager = get_node("/root/Game/GameManager")
	if not game_manager:
		push_error("GameManager not found!")
		return

	# Create dummy pieces
	var white_pawn = PAWN_SCENE.instantiate()
	white_pawn.color = Piece.PieceColor.WHITE
	white_pawn.apply_blueprint(PAWN_BLUEPRINT)
	white_pawn.name = "WhitePawn"

	var black_pawn = PAWN_SCENE.instantiate()
	black_pawn.color = Piece.PieceColor.BLACK
	black_pawn.apply_blueprint(PAWN_BLUEPRINT)
	black_pawn.name = "BlackPawn"

	# Set combatants in GameManager
	game_manager.current_attacker = white_pawn
	game_manager.current_defender = black_pawn

	# Instantiate and add the Battle scene
	var battle_instance = BATTLE_SCENE.instantiate()
	add_child(battle_instance)
