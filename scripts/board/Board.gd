extends Node2D
class_name Board

@export var board_size: int = 8
@export var tile_px: int = 64
@export var light_color: Color = Color("#f0d9b5")
@export var dark_color: Color  = Color("#b58863")
@export var debug_mode: bool = true

const TILE_SCN := preload("res://scenes/Tile.tscn")

var _selected_piece: Piece = null
var _legal_moves: Array[Vector2i] = []
var _tiles: Dictionary = {}  # Vector2i -> Tile
var _piece_index: Dictionary = {}  # Vector2i -> Piece (índice rápido)
var _moving: bool = false
var current_turn: Piece.PieceColor = Piece.PieceColor.WHITE  # Turno inicial: Blanco

func _ready() -> void:
	_generate_tiles()
	# REFACTOR: Solo snap si las coordenadas no están definidas manualmente
	for child in $Pieces.get_children():
		if child is Piece and child.initial_coord.x < 0:
			_snap_all_pieces_to_grid()
	_rebuild_index()
	if debug_mode:
		_validate_unique_coords()
		_debug_dump_board()
		_update_tiles_overlay()
		print("[TURN] Turno inicial: ", _color_str(current_turn))
	queue_redraw()

func _draw() -> void:
	pass  # Fondo opcional si lo necesitas

func _generate_tiles() -> void:
	var tiles_node := $Tiles
	for child in tiles_node.get_children():
		child.queue_free()
	_tiles.clear()

	for y in board_size:
		for x in board_size:
			var tile := TILE_SCN.instantiate()
			tiles_node.add_child(tile)
			tile.coord = Vector2i(x, y)
			tile.size_px = tile_px
			tile.position = Vector2(x, y) * tile_px
			tile.set_checker_color(((x + y) % 2) == 0, light_color, dark_color)
			tile.clicked.connect(_on_tile_clicked)
			print("Conectando señal clicked para tile en ", Vector2i(x, y))  # Depuración
			_tiles[Vector2i(x, y)] = tile

func move_piece_to(piece: Piece, target_coord: Vector2i) -> void:
	if _moving or piece.color != current_turn:
		if debug_mode:
			if _moving:
				push_warning("[MOVE] Ignorando: otro movimiento en progreso.")
			else:
				push_warning("[MOVE] Ignorando: no es turno de ", _color_str(piece.color))
		return
	_moving = true

	var occupying_piece: Piece = get_piece_at(target_coord)
	if debug_mode:
		var occ_desc = (occupying_piece.name + " " + _color_str(occupying_piece.color)) if occupying_piece else "None"
		print("[MOVE] ", piece.name, " ", _color_str(piece.color), " de ", piece.coord, " -> ", target_coord, " | ocupante=", occ_desc)

	if occupying_piece:
		if occupying_piece.color == piece.color:
			if debug_mode:
				push_warning("[MOVE] Ilegal: misma color en destino.")
			_moving = false
			return
		else:
			_piece_index.erase(occupying_piece.coord)
			occupying_piece.queue_free()

	piece.coord = target_coord

	if debug_mode and get_piece_at(target_coord) != piece:
		push_error("[MOVE] Índice desincronizado tras mover.")

	clear_selection()
	if debug_mode:
		_update_tiles_overlay()
	_moving = false
	# Cambiar turno después de un movimiento válido
	current_turn = Piece.PieceColor.BLACK if current_turn == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE
	if debug_mode:
		print("[TURN] Turno cambiado a: ", _color_str(current_turn))

func _on_tile_clicked(coord: Vector2i) -> void:
	if _moving:  # Evitar interacciones durante un movimiento
		if debug_mode:
			print("[TILE_CLICK] Ignorando: movimiento en progreso.")
		return

	if debug_mode:
		print("[TILE_CLICK] Recibido clic en coord: ", coord, " | Seleccionada: ", _selected_piece.name if _selected_piece else "Ninguna")

	if _selected_piece:  # Solo procesamos clics si hay una pieza seleccionada
		if debug_mode:
			print("[TILE_CLICK] Movimientos legales: ", _legal_moves, " | Coord en legales: ", coord in _legal_moves)
		# Si ya hay una pieza seleccionada, intenta moverla
		if coord in _legal_moves:
			if debug_mode:
				print("[TILE_CLICK] Ejecutando move_piece_to a ", coord)
			move_piece_to(_selected_piece, coord)
		else:
			# Deseleccionar si se hace clic fuera de un movimiento legal
			if debug_mode:
				print("[TILE_CLICK] Deseleccionando por clic fuera de movimiento legal.")
			clear_selection()

func _on_piece_coord_changed(p: Piece, old_c: Vector2i, new_c: Vector2i) -> void:
	if _piece_index.has(old_c) and _piece_index[old_c] == p:
		_piece_index.erase(old_c)
	if _piece_index.has(new_c) and _piece_index[new_c] != p:
		push_warning("[Board] Colisión en ", new_c, " entre ", _piece_index[new_c].name, " y ", p.name)
	_piece_index[new_c] = p

func _highlight_moves(moves: Array[Vector2i]) -> void:
	for c in moves:
		if _tiles.has(c):
			_tiles[c].set_highlight(true)

func clear_selection() -> void:
	_selected_piece = null
	_legal_moves.clear()
	for t in _tiles.values():
		t.set_highlight(false)

func select_piece(p: Piece) -> void:
	if p.color != current_turn:
		if debug_mode:
			print("[SELECT] Ignorando: no es turno de ", _color_str(p.color))
		return
	if debug_mode:
		print("[SELECT] Seleccionando pieza: ", p.name, " con movimientos: ", p.get_moves(self))
	clear_selection()
	_selected_piece = p
	_legal_moves = p.get_moves(self)
	if debug_mode:
		print("[SELECT] Movimientos legales: ", _legal_moves)
	_highlight_moves(_legal_moves)

func is_coord_empty(coord: Vector2i) -> bool:
	var is_empty := (coord.x >= 0 and coord.x < board_size and 
					 coord.y >= 0 and coord.y < board_size and 
					 get_piece_at(coord) == null)
	if debug_mode:
		print("[DEBUG] is_coord_empty(", coord, ") = ", is_empty, " | piece_at=", get_piece_at(coord))
	return is_empty

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
	c = c.clamp(Vector2i(0, 0), Vector2i(board_size - 1, board_size - 1))
	return c

func _snap_all_pieces_to_grid() -> void:
	for child in $Pieces.get_children():
		if child is Piece and child.initial_coord.x < 0:
			var local_pos := to_local(child.global_position)
			child.coord = position_to_coord(local_pos)

func _rebuild_index() -> void:
	_piece_index.clear()
	for child in $Pieces.get_children():
		if child is Piece:
			if _piece_index.has(child.coord):
				if debug_mode:
					push_error("[Board] Dos piezas en ", child.coord, ": ", _piece_index[child.coord].name, " y ", child.name)
			_piece_index[child.coord] = child

func _validate_unique_coords() -> void:
	var seen := {}
	for child in $Pieces.get_children():
		if child is Piece:
			if seen.has(child.coord):
				push_error("[Board] Duplicado en ", child.coord, ": ", seen[child.coord].name, " y ", child.name)
			seen[child.coord] = child

func _debug_dump_board() -> void:
	print("--- BOARD DUMP ---")
	for y in range(board_size):
		var row := ""
		for x in range(board_size):
			var c := Vector2i(x, y)
			var p: Piece = get_piece_at(c)
			row += "w" if p and p.color == Piece.PieceColor.WHITE else "b" if p and p.color == Piece.PieceColor.BLACK else "."
		print(str(y), " | ", row)
	print("------------------")

func _update_tiles_overlay() -> void:
	if not debug_mode:
		return
	for coord in _tiles.keys():
		var tile: Tile = _tiles[coord]
		var occ: Piece = get_piece_at(coord)
		var txt := str(coord)
		if occ:
			txt += " | " + occ.name + " " + _color_str(occ.color)
		tile.set_overlay_text(txt)

func _color_str(c: int) -> String:
	return "WHITE" if c == Piece.PieceColor.WHITE else "BLACK"

func get_legal_moves() -> Array[Vector2i]:
	return _legal_moves
