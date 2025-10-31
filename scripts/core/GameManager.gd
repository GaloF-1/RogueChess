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

func _ready() -> void:
	_player = Player

	if not _board or not _shop_ui or not _player or not king_blueprint:
		push_error("GameManager: ¡Nodos, singleton Player o king_blueprint no configurados!")
		get_tree().quit()
		return
		
	_board.combat_ended.connect(_on_combat_ended)
	
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

	_spawn_enemies_for_round(round_num)
	_board.start_combat()

func _spawn_enemies_for_round(round_num: int) -> void:
	_board.clear_enemies()
	
	var num_enemies: int
	match round_num:
		1: num_enemies = randi_range(1, 2)
		2: num_enemies = randi_range(2, 4)
		_: num_enemies = randi_range(3, 5)

	print("Spawneando %d enemigos para la ronda %d." % [num_enemies, round_num])
	for i in range(num_enemies):
		if enemy_blueprints.is_empty():
			push_warning("No hay blueprints de enemigos configurados.")
			break
			
		var bp = enemy_blueprints.pick_random()
		var spawn_coord = _board.get_random_empty_enemy_square()
		
		if spawn_coord != Vector2i(-1, -1):
			_board.place_new_piece(bp, spawn_coord, Piece.PieceColor.BLACK)
		else:
			break

func _on_combat_ended(winner: Piece.PieceColor) -> void:
	if winner == Piece.PieceColor.WHITE:
		print("RONDA %d SUPERADA" % _current_round)
		transition_to_phase(GamePhase.SHOP)
	else:
		print("--- DERROTA ---")
		get_tree().quit()
