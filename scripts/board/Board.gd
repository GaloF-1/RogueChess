extends Node2D
class_name Board

signal combat_ended(winner: Piece.PieceColor)
signal combat_initiated(attacker: Piece, defender: Piece)

@export var board_size: int = 8
@export var tile_px: int = 64
@export var light_color: Color = Color("#f0d9b5")
@export var dark_color: Color = Color("#b58863")
@export var debug_mode: bool = true
@export var player_rows: int = 2

const TILE_SCN := preload("res://scenes/chess/Tile.tscn")

var _selected_piece: Piece = null
var _legal_moves: Array[Vector2i] = []
var _tiles: Dictionary = {}  # Vector2i -> Tile
var _piece_index: Dictionary = {}  # Vector2i -> Piece
var _moving: bool = false
var current_turn: Piece.PieceColor = Piece.PieceColor.WHITE

var is_arrangement_mode: bool = false
var arrangement_color: Piece.PieceColor

var _player: Player

var enemy_blueprints: Array[PieceBlueprint] = []

func _ready() -> void:
	_player = Player
	print("[DEBUG] Board: Referencia al singleton 'Player' obtenida.")

	_generate_tiles()
	_rebuild_index()
	add_to_group("board")
	if debug_mode:
		_validate_unique_coords()
		_debug_dump_board()
		_update_tiles_overlay()

func setup_next_round(round_num: int) -> void:
	print("[Board] Configurando la siguiente ronda.")
	clear_enemies()
	current_turn = Piece.PieceColor.WHITE

	spawn_enemies(round_num)

	_rebuild_index()
	if debug_mode:
		_update_tiles_overlay()

func spawn_enemies(round_num: int) -> void:

	var num_enemies: int

	match round_num:

		1: num_enemies = randi_range(1, 2)

		2: num_enemies = randi_range(2, 4)

		_: num_enemies = randi_range(3, 5)



	# Filtrar blueprints de enemigos según la ronda

	var available_blueprints: Array[PieceBlueprint] = []

	if round_num < 3: # Rondas 1-2: Sin Reinas ni Torres

		available_blueprints = enemy_blueprints.filter(func(bp): return bp.type != Enums.PieceType.QUEEN and bp.type != Enums.PieceType.ROOK)

	elif round_num < 5: # Rondas 3-4: Sin Reinas

		available_blueprints = enemy_blueprints.filter(func(bp): return bp.type != Enums.PieceType.QUEEN)

	else: # Ronda 5 en adelante: Todas las piezas disponibles

		available_blueprints = enemy_blueprints



	if available_blueprints.is_empty():

		push_warning("No hay blueprints de enemigos disponibles para la ronda %d." % round_num)

		return



	print("[Board] Spawneando %d enemigos para la ronda %d." % [num_enemies, round_num])

	for i in range(num_enemies):

		var bp = available_blueprints.pick_random()

		

		var spawn_coord = get_random_empty_enemy_square()

		

		if spawn_coord != Vector2i(-1, -1):

			place_new_piece(bp, spawn_coord, Piece.PieceColor.BLACK)

		else:

			break # No more space



func resize_board(new_size: int) -> void:
	var old_size = board_size
	
	# 1. Guardar las piezas del jugador
	var preserved_pieces: Array[Dictionary] = []
	for piece in $Pieces.get_children():
		if piece is Piece and piece.color == Piece.PieceColor.WHITE:
			preserved_pieces.append({"piece": piece, "coord": piece.coord})
			$Pieces.remove_child(piece) # Quitar de la escena temporalmente sin liberar

	# 2. Limpiar el tablero (elimina enemigos y tiles)
	clear_enemies()
	for child in $Tiles.get_children():
		child.queue_free()
	_tiles.clear()

	# 3. Regenerar el tablero con el nuevo tamaño
	board_size = new_size
	_generate_tiles()
	print("[Board] Tablero redimensionado a %dx%d" % [new_size, new_size])

	# 4. Recolocar las piezas del jugador
	for item in preserved_pieces:
		var piece: Piece = item["piece"]
		var old_coord: Vector2i = item["coord"]
		
		# Calcular nueva coordenada relativa al fondo
		var old_relative_y = old_size - old_coord.y
		var new_y = new_size - old_relative_y
		var new_coord = Vector2i(old_coord.x, new_y)
		
		# Añadir la pieza de nuevo y establecer su nueva coordenada
		$Pieces.add_child(piece)
		piece.coord = new_coord

	_rebuild_index()
	if debug_mode:
		_update_tiles_overlay()

func place_new_piece(blueprint: PieceBlueprint, coord: Vector2i, piece_color: Piece.PieceColor) -> void:
	if not blueprint: push_error("Blueprint nulo"); return

	var new_piece := blueprint.instantiate()
	if new_piece:
		new_piece.apply_blueprint(blueprint)
		$Pieces.add_child(new_piece)
		new_piece.color = piece_color
		new_piece.coord = coord
	else:
		push_error("No se pudo instanciar la pieza desde el blueprint.")

func move_piece_to(piece: Piece, target_coord: Vector2i) -> void:
	if _moving or piece.color != current_turn: return
	_moving = true

	var occupying_piece: Piece = get_piece_at(target_coord)
	if occupying_piece:
		if occupying_piece.color == piece.color:
			_moving = false
			return
		else:
			# An opponent is on the target tile, initiate combat
			print("[Board] Combat initiated between ", piece.name, " and ", occupying_piece.name)
			combat_initiated.emit(piece, occupying_piece)
			_moving = false # Stop the move until combat is resolved
			clear_selection()
			return # Do not complete the move

	# If the tile is empty, just move the piece
	piece.coord = target_coord
	clear_selection()
	
	_moving = false
	
	if not is_arrangement_mode:
		current_turn = Piece.PieceColor.BLACK if current_turn == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE
		_check_victory_condition()

func _on_tile_clicked(coord: Vector2i) -> void:
	if _moving or is_arrangement_mode: return

	if _selected_piece:
		if coord in _legal_moves:
			move_piece_to(_selected_piece, coord)
		else:
			clear_selection()

func _on_piece_coord_changed(p: Piece, old_c: Vector2i, new_c: Vector2i) -> void:
	if _piece_index.has(old_c) and _piece_index[old_c] == p:
		_piece_index.erase(old_c)
	_piece_index[new_c] = p

func select_piece(p: Piece) -> void:
	if is_arrangement_mode or p.color != current_turn: return
		
	clear_selection()
	_selected_piece = p
	_legal_moves = p.get_moves(self)
	_highlight_moves(_legal_moves)

func set_arrangement_mode(is_enabled: bool, for_color: Piece.PieceColor) -> void:
	is_arrangement_mode = is_enabled
	arrangement_color = for_color

func start_combat() -> void:
	current_turn = Piece.PieceColor.WHITE

func clear_enemies() -> void:
	for piece in $Pieces.get_children():
		if piece is Piece and piece.color == Piece.PieceColor.BLACK:
			piece.queue_free()
	_rebuild_index()

func get_random_empty_enemy_square() -> Vector2i:
	var enemy_squares: Array[Vector2i] = []
	for y in range(board_size - player_rows):
		for x in range(board_size):
			var coord = Vector2i(x, y)
			if get_piece_at(coord) == null:
				enemy_squares.append(coord)
	
	if enemy_squares.is_empty(): return Vector2i(-1, -1)
	return enemy_squares.pick_random()

func is_valid_arrangement_square(coord: Vector2i) -> bool:
	var player_start_row = board_size - player_rows
	return coord.y >= player_start_row and coord.y < board_size

func _check_victory_condition() -> void:
	var white_pieces_count = 0
	var black_pieces_count = 0
	for piece in _piece_index.values():
		if not is_instance_valid(piece): continue
		if piece.color == Piece.PieceColor.WHITE: white_pieces_count += 1
		else: black_pieces_count += 1
	
	if white_pieces_count == 0: combat_ended.emit(Piece.PieceColor.BLACK)
	elif black_pieces_count == 0: combat_ended.emit(Piece.PieceColor.WHITE)

func _generate_tiles() -> void:
	for child in $Tiles.get_children():
		child.queue_free()
	_tiles.clear()

	for y in board_size:
		for x in board_size:
			var tile := TILE_SCN.instantiate()
			$Tiles.add_child(tile)
			tile.coord = Vector2i(x, y)
			tile.size_px = tile_px
			tile.position = Vector2(x, y) * tile_px
			tile.set_checker_color(((x + y) % 2) == 0, light_color, dark_color)
			tile.clicked.connect(_on_tile_clicked)
			_tiles[Vector2i(x, y)] = tile

func _highlight_moves(moves: Array[Vector2i]) -> void:
	for c in moves:
		if _tiles.has(c): _tiles[c].set_highlight(true)

func clear_selection() -> void:
	_selected_piece = null
	_legal_moves.clear()
	for t in _tiles.values(): t.set_highlight(false)

func is_coord_empty(coord: Vector2i) -> bool:
	return get_piece_at(coord) == null

func get_piece_at(coord: Vector2i) -> Piece:
	var p = _piece_index.get(coord)
	if p and not is_instance_valid(p):
		_piece_index.erase(coord)
		return null
	return p

func coord_to_position(coord: Vector2i) -> Vector2:
	return Vector2(coord) * tile_px + Vector2(tile_px / 2, tile_px / 2)

func position_to_coord(pos: Vector2) -> Vector2i:
	var c := Vector2i(floor(pos.x / float(tile_px)), floor(pos.y / float(tile_px)))
	return c.clamp(Vector2i(0, 0), Vector2i(board_size - 1, board_size - 1))

func _rebuild_index() -> void:
	_piece_index.clear()
	for child in $Pieces.get_children():
		if child is Piece:
			_piece_index[child.coord] = child

func _validate_unique_coords() -> void:
	var seen := {}
	for child in $Pieces.get_children():
		if child is Piece:
			if seen.has(child.coord): push_error("Duplicado en ", child.coord)
			seen[child.coord] = child

func _debug_dump_board() -> void:
	pass

func _update_tiles_overlay() -> void:
	if not debug_mode: return
	for coord in _tiles.keys():
		var tile: Tile = _tiles[coord]
		var occ: Piece = get_piece_at(coord)
		var txt := str(coord)
		if occ: txt += " | " + occ.name + " " + _color_str(occ.color)
		tile.set_overlay_text(txt)

func finalize_round_setup() -> void:
	_rebuild_index()
	if debug_mode:
		_update_tiles_overlay()

func heal_all_player_pieces() -> void:
	for piece in _piece_index.values():
		if is_instance_valid(piece) and piece.color == Piece.PieceColor.WHITE:
			piece.heal_to_full()
	print("[Board] Todas las piezas del jugador han sido curadas.")


func _color_str(c: int) -> String:
	return "WHITE" if c == Piece.PieceColor.WHITE else "BLACK"

func get_legal_moves() -> Array[Vector2i]:
	return _legal_moves


func clear_coord_from_index(coord: Vector2i) -> void:
	if _piece_index.has(coord):
		_piece_index.erase(coord)


func clear_board() -> void:
	for piece in $Pieces.get_children():
		piece.queue_free()
	_piece_index.clear()

func resolve_combat_outcome(winner: Piece, loser: Piece, original_attacker: Piece, original_defender: Piece) -> void:
	print("[Board] Resolving combat outcome.")

	# The loser is already freed, but we need to ensure it's removed from the index
	if is_instance_valid(loser) and _piece_index.has(loser.coord):
		_piece_index.erase(loser.coord)

	# Reparent the winner back to this board
	winner.get_parent().remove_child(winner)
	$Pieces.add_child(winner)
	winner.end_combat() # Revert sprite

	# If the attacker won, move it to the defender's spot
	if winner == original_attacker:
		winner.coord = original_defender.coord
	else:
		# Defender won. Its coord is correct, but we need to update its visual position.
		# Re-assigning the coord will trigger the setter which updates the position.
		winner.coord = winner.coord

	_rebuild_index()
	if debug_mode:
		_update_tiles_overlay()

	# Progress the turn
	if not is_arrangement_mode:
		current_turn = Piece.PieceColor.BLACK if current_turn == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE

	# Check if this was the last piece
	_check_victory_condition()
