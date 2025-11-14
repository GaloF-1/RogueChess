extends Node
class_name GameManager

enum GamePhase { 
	SHOP,      # El jugador compra y organiza sus piezas.
	COMBAT     # Las piezas luchan.
}

signal game_over

signal phase_changed(new_phase: GamePhase)
signal round_changed(new_round: int)

@export_group("Blueprints")
@export var king_blueprint: PieceBlueprint
@export var enemy_blueprints: Array[PieceBlueprint] = []

@onready var _board: Board = get_node("../Board")
@onready var _shop_ui: Control = get_node("../ShopUI")
var _player

var _current_round: int = 0:
	set(value):
		if _current_round != value:
			_current_round = value
			round_changed.emit(_current_round)

var _current_phase: GamePhase:
	set(value):
		if _current_phase != value:
			_current_phase = value
			phase_changed.emit(_current_phase)

# --- Combat State ---
var current_attacker: Piece = null
var current_defender: Piece = null

func _ready() -> void:
	_player = Player

	if not _board or not _shop_ui or not _player or not king_blueprint:
		push_error("GameManager: ¡Nodos, singleton Player o king_blueprint no configurados!")
		get_tree().quit()
		return
		
	_board.enemy_blueprints = enemy_blueprints
	_board.combat_ended.connect(_on_combat_ended)
	_board.combat_initiated.connect(_on_combat_initiated)
	_shop_ui.next_round_requested.connect(Callable(self, "transition_to_phase").bind(GamePhase.COMBAT))
	
	# Do not start a new run automatically, wait for Main scene
	# start_new_run()

func start_new_run() -> void:
	print("--- NUEVA PARTIDA INICIADA ---")
	_board.clear_board()
	self._current_round = 0
	_player.reset()
	transition_to_phase(GamePhase.SHOP)

func transition_to_phase(new_phase: GamePhase) -> void:
	print("Transicionando a la fase: %s" % GamePhase.keys()[new_phase])
	self._current_phase = new_phase
	
	match _current_phase:
		GamePhase.SHOP:
			# Setup for the very first round
			if _current_round == 0:
				_board.resize_board(3)
				_board.place_new_piece(king_blueprint, Vector2i(1, 2), Piece.PieceColor.WHITE)

			# Logic for all shop phases (including the first)
			_shop_ui.show()
			_board.set_arrangement_mode(true, Piece.PieceColor.WHITE)
			var shop_logic = _shop_ui.get_node_or_null("Shop")
			if shop_logic:
				shop_logic.generate_offers()

		GamePhase.COMBAT:
			self._current_round += 1
			
			match _current_round:
				3:
					_board.resize_board(4)
				5:
					_board.resize_board(5)

			_setup_round(_current_round)
			
			_shop_ui.hide()
			_board.set_arrangement_mode(false, Piece.PieceColor.WHITE)
			_board.start_combat()


func _setup_round(round_num: int) -> void:
	# This function is now only for spawning enemies for the current round
	_board.spawn_enemies(round_num)
	_board.finalize_round_setup()


func _check_for_king_death(piece: Piece) -> bool:
	if piece and piece.blueprint == king_blueprint and piece.color == Piece.PieceColor.WHITE:
		print("--- GAME OVER: El Rey ha sido derrotado. ---")
		game_over.emit()
		return true
	return false

func _on_combat_ended(winner: Piece.PieceColor) -> void:
	if winner == Piece.PieceColor.WHITE:
		print("RONDA %d SUPERADA" % _current_round)
		
		_board.heal_all_player_pieces()

		# Award gold and interest after winning a round
		_player.add_gold(10)
		var interest_gold = floor(_player.gold / 5)
		if interest_gold > 0:
			_player.add_gold(interest_gold)
			print("[GameManager] Intereses añadidos: ", interest_gold, " | Total: ", _player.gold)
		
		transition_to_phase(GamePhase.SHOP)
	else:
		print("--- DERROTA ---")
		game_over.emit()

func _on_combat_initiated(attacker: Piece, defender: Piece) -> void:
	print("GameManager: Combat initiated between ", attacker.name, " and ", defender.name)
	self.current_attacker = attacker
	self.current_defender = defender
	
	# Hide the main scene, but don't free it
	get_parent().visible = false
	
	# Load and instance the battle scene
	var battle_scene = load("res://scenes/chess/Battle.tscn").instantiate()
	get_tree().get_root().add_child(battle_scene)
	
	# Connect to the battle scene's finished signal and set it up
	var combat_manager = battle_scene as CombatManager
	if combat_manager:
		combat_manager.setup(self)
		combat_manager.combat_finished.connect(_on_combat_finished)
		combat_manager.combat_draw.connect(_on_combat_draw)

func _on_combat_finished(winner: Piece, loser: Piece) -> void:
	if _check_for_king_death(loser):
		return

	print("GameManager: Combat finished. Winner: ", winner.name)
	
	# Show the main scene again
	get_parent().visible = true
	
	# Resolve the outcome on the board
	_board.resolve_combat_outcome(winner, loser, current_attacker, current_defender)
	
	# Clean up combat state
	self.current_attacker = null
	self.current_defender = null

	# Now it is safe to free the loser piece
	if is_instance_valid(loser):
		loser.queue_free()

func _on_combat_draw() -> void:
	if _check_for_king_death(current_attacker) or _check_for_king_death(current_defender):
		return
		
	print("GameManager: Combat ended in a draw.")
	
	# Show the main scene again
	get_parent().visible = true

	# Store coords before the instances are freed
	var attacker_coord = current_attacker.coord
	var defender_coord = current_defender.coord

	# Both pieces are defeated. Remove them from the game.
	if is_instance_valid(current_attacker):
		current_attacker.queue_free()
	if is_instance_valid(current_defender):
		current_defender.queue_free()
	
	# Explicitly clear the board's index for these coordinates
	_board.clear_coord_from_index(attacker_coord)
	_board.clear_coord_from_index(defender_coord)

	# Update the board state by checking if a side has been wiped out
	_board._check_victory_condition()

	# Clean up combat state
	self.current_attacker = null
	self.current_defender = null
