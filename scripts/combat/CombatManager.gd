extends Node2D

signal piece_defeated_in_combat(victim: Piece, killer: Piece)
signal combat_finished(winner: Piece, loser: Piece)

# --- NODES ---
@onready var white_team_node = $WhiteTeam
@onready var black_team_node = $BlackTeam
@onready var initial_delay_timer = $InitialDelayTimer

# --- VARS ---
var white_pieces = []
var black_pieces = []
var is_battle_active = false
var loser: Piece = null

# --- CONSTANTS ---
const INITIAL_DELAY = 1.0 # Seconds before battle starts

func _ready():
	var game_manager = get_node("/root/Game/GameManager")
	if not game_manager or not is_instance_valid(game_manager.current_attacker) or not is_instance_valid(game_manager.current_defender):
		print("Error: CombatManager could not find valid combatants in GameManager.")
		queue_free()
		return

	var attacker = game_manager.current_attacker
	var defender = game_manager.current_defender

	# Determine which piece is white and which is black
	var white_piece: Piece
	var black_piece: Piece

	if attacker.color == Piece.PieceColor.WHITE:
		white_piece = attacker
		black_piece = defender
	else:
		white_piece = defender
		black_piece = attacker

	# Reparent pieces to the battle scene
	white_piece.get_parent().remove_child(white_piece)
	black_piece.get_parent().remove_child(black_piece)

	white_team_node.add_child(white_piece)
	black_team_node.add_child(black_piece)

	white_pieces = [white_piece]
	black_pieces = [black_piece]

	# Connect signals
	white_piece.defeated.connect(_on_piece_defeated)
	black_piece.defeated.connect(_on_piece_defeated)

	start_battle()

func start_battle():
	if white_pieces.is_empty() or black_pieces.is_empty():
		print("Battle cannot start: one or both teams are empty.")
		return
	
	print("--- BATTLE STARTING IN ", INITIAL_DELAY, " SECONDS ---")
	initial_delay_timer.wait_time = INITIAL_DELAY
	initial_delay_timer.one_shot = true
	initial_delay_timer.start()

func _on_initial_delay_timer_timeout():
	print("--- BATTLE STARTED! FIGHT! ---")
	is_battle_active = true
	set_process(true)

	# Switch to battle sprites and provide opponent lists
	for piece in white_pieces:
		piece.begin_combat(black_pieces)
	for piece in black_pieces:
		piece.begin_combat(white_pieces)

func _process(delta): 
	if not is_battle_active: return

	# Check for victory/defeat conditions
	if black_pieces.is_empty():
		var winner = white_pieces[0]
		print("--- ATTACKER WINS! ---")
		is_battle_active = false
		set_process(false)
		combat_finished.emit(winner, loser)
		queue_free()
	
	if white_pieces.is_empty():
		var winner = black_pieces[0]
		print("--- DEFENDER WINS! ---")
		is_battle_active = false
		set_process(false)
		combat_finished.emit(winner, loser)
		queue_free()

func _on_piece_defeated(victim: Piece, killer: Piece) -> void:
	self.loser = victim
	if victim.color == Piece.PieceColor.WHITE:
		var index = white_pieces.find(victim)
		if index != -1:
			white_pieces.remove_at(index)
	else:
		var index = black_pieces.find(victim)
		if index != -1:
			black_pieces.remove_at(index)

	piece_defeated_in_combat.emit(victim, killer)
