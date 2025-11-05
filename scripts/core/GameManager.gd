extends Node
class_name GameManager

enum GamePhase { 
	SHOP,      # El jugador compra y organiza sus piezas.
	COMBAT     # Las piezas luchan.
}

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
	
	start_new_run()

func start_new_run() -> void:
	print("--- NUEVA PARTIDA INICIADA ---")
	self._current_round = 1
	_setup_round(_current_round)

func transition_to_phase(new_phase: GamePhase) -> void:
	print("Transicionando a la fase: %s" % GamePhase.keys()[new_phase])
	self._current_phase = new_phase
	
	match _current_phase:
		GamePhase.SHOP:
			_shop_ui.show()
			_board.set_arrangement_mode(true, Piece.PieceColor.WHITE)
			var shop_logic = _shop_ui.get_node_or_null("Shop")
			if shop_logic:
				shop_logic.generate_offers()

		GamePhase.COMBAT:
			self._current_round += 1
			_setup_round(_current_round)

func _setup_round(round_num: int) -> void:
	_shop_ui.hide()
	_board.set_arrangement_mode(false, Piece.PieceColor.WHITE)

	match round_num:
		1:
			_board.resize_board(3)
			_board.place_new_piece(king_blueprint, Vector2i(1, 2), Piece.PieceColor.WHITE)

	_board.spawn_enemies(round_num)
	_board.finalize_round_setup()
	_board.start_combat()

func _on_combat_ended(winner: Piece.PieceColor) -> void:
	if winner == Piece.PieceColor.WHITE:
		print("RONDA %d SUPERADA" % _current_round)
		transition_to_phase(GamePhase.SHOP)
	else:
		print("--- DERROTA ---")
		get_tree().quit()

func _on_combat_initiated(attacker: Piece, defender: Piece) -> void:
	print("GameManager: Combat initiated between ", attacker.name, " and ", defender.name)
	self.current_attacker = attacker
	self.current_defender = defender
	
	# Hide the main scene, but don't free it
	get_parent().visible = false
	
	# Load and instance the battle scene
	var battle_scene = load("res://scenes/tests/TestBattle.tscn").instantiate()
	get_tree().get_root().add_child(battle_scene)
	
	# Connect to the battle scene's finished signal
	var combat_manager = battle_scene # Assuming the root of the battle scene is the CombatManager
	if combat_manager:
		combat_manager.combat_finished.connect(_on_combat_finished)

func _on_combat_finished(winner: Piece, loser: Piece) -> void:
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
