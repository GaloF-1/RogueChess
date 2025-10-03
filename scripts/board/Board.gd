extends Node2D
class_name Board

@export var board_size: int = 8
@export var tile_px: int = 64
@export var light_color: Color = Color("#f0d9b5")
@export var dark_color: Color  = Color("#b58863")
@export var debug_mode: bool = true  # ← activar/desactivar debug

const TILE_SCN := preload("res://scenes/Tile.tscn")

var _selected_piece: Piece = null
var _legal_moves: Array[Vector2i] = []
var _tiles: Dictionary[Vector2i, Tile] = {} 
var _moving: bool = false

# Índice rápido para piezas (evita O(n) y ayuda a detectar inconsistencias)
var _piece_index: Dictionary[Vector2i, Piece] = {}


func _ready() -> void:
	_generate_tiles()
	_snap_all_pieces_to_grid()
	_rebuild_index()
	if debug_mode:
		_validate_unique_coords()
		_debug_dump_board()
		_update_tiles_overlay()
	queue_redraw()

func _draw() -> void:
	# Si querés un fondo liso detrás del tablero, dejá solo esto:
	# draw_rect(Rect2(Vector2.ZERO, Vector2(board_size, board_size) * tile_px), Color("#e6e6e6"))
	pass

func _generate_tiles() -> void:
	var tiles_node := $Tiles

	# Borrar casillas anteriores (si re-generamos el tablero)
	for child in tiles_node.get_children():
		child.queue_free()
	_tiles.clear()  # o: _tiles = {}

	# Crear casillas nuevas
	for y in board_size:
		for x in board_size:
			var tile := TILE_SCN.instantiate()
			tiles_node.add_child(tile)
			tile.coord = Vector2i(x, y)
			tile.size_px = tile_px
			tile.position = Vector2(x, y) * tile_px
			tile.set_checker_color(((x + y) % 2) == 0, light_color, dark_color)
			tile.clicked.connect(_on_tile_clicked)
			_tiles[Vector2i(x, y)] = tile


func _on_tile_clicked(coord: Vector2i) -> void:
	if _selected_piece:
		# mover si es legal
		if coord in _legal_moves:
			_move_piece_to(_selected_piece, coord)
			_clear_selection()
		else:
			_clear_selection()
	else:
		# seleccionar pieza si hay alguna en esa casilla
		var p : Piece = get_piece_at(coord)
		if p:
			_selected_piece = p
			_legal_moves = p.get_moves(self) # Board se pasa como contexto
			_highlight_moves(_legal_moves)



func _move_piece_to(piece, coord: Vector2i) -> void:
	# Captura simple si hay una pieza enemiga
	var other := get_piece_at(coord)
	if other and other.color != piece.color:
		other.queue_free()

	piece.coord = coord
	piece.position = Vector2(coord) * tile_px + Vector2(tile_px/2, tile_px/2) # centro


func _on_piece_coord_changed(p: Piece, old_c: Vector2i, new_c: Vector2i) -> void:
	if _piece_index.has(old_c) and _piece_index[old_c] == p:
		_piece_index.erase(old_c)
	if _piece_index.has(new_c) and _piece_index[new_c] != p:
		push_warning("[Board] Colisión en " + str(new_c) + " entre " + _piece_index[new_c].name + " y " + p.name)
	_piece_index[new_c] = p



func _highlight_moves(moves: Array[Vector2i]) -> void:
	for c in moves:
		if _tiles.has(c):
			_tiles[c].set_highlight(true)


func _clear_selection() -> void:
	_selected_piece = null
	_legal_moves.clear()
	for t in _tiles.values():
		t.set_highlight(false)


func move_piece_to(piece: Piece, target_coord: Vector2i) -> void:
	if _moving:
		if debug_mode:
			push_warning("[MOVE] Ignorando movimiento: otro en progreso.")
		return
	_moving = true

	var occupying_piece: Piece = get_piece_at(target_coord)
	var occupying_desc := "None"
	if occupying_piece:
		occupying_desc = occupying_piece.name + " " + _color_str(occupying_piece.color)
	if debug_mode:
		print("[MOVE] ", piece.name, " ", _color_str(piece.color),
			  " de ", piece.coord, " -> ", target_coord, " | destino ocupante=", occupying_desc)

	if occupying_piece and occupying_piece.color != piece.color:
		_piece_index.erase(occupying_piece.coord)
		occupying_piece.visible = false
		occupying_piece.process_mode = Node.PROCESS_MODE_DISABLED
		occupying_piece.draggable = false
		occupying_piece.free()
		occupying_piece = null

	if occupying_piece and occupying_piece.color == piece.color:
		if debug_mode:
			push_warning("[MOVE] Movimiento ilegal: misma pieza en destino.")
		_moving = false
		return

	piece.coord = target_coord

	if debug_mode and get_piece_at(target_coord) != piece:
		push_error("[MOVE] Índice desincronizado tras mover " + piece.name + " a " + str(target_coord))

	_rebuild_index()  # Sincronizar índice inmediatamente
	clear_selection()
	if debug_mode:
		_update_tiles_overlay()
	_moving = false


# Verifica si una coordenada está vacía (dentro del tablero y sin pieza).
func is_coord_empty(coord: Vector2i) -> bool:
	var is_empty := (coord.x >= 0 and coord.x < board_size and 
					 coord.y >= 0 and coord.y < board_size and 
					 get_piece_at(coord) == null)
	if debug_mode:
			print("[DEBUG] is_coord_empty(", coord, ") = ", is_empty, " | piece_at=", get_piece_at(coord))
	return is_empty


func get_piece_at(coord: Vector2i) -> Piece:
	var p = _piece_index.get(coord)
	if p == null:
		return null
	# Evita devolver una instancia muerta
	if not is_instance_valid(p):
		_piece_index.erase(coord)
		return null
	return p


# Helpers coord <-> posición local al Board
func coord_to_position(coord: Vector2i) -> Vector2:
	return Vector2(coord) * tile_px + Vector2(tile_px / 2, tile_px / 2)

func position_to_coord(pos: Vector2) -> Vector2i:
	var c := Vector2i(floor(pos.x / float(tile_px)), floor(pos.y / float(tile_px)))
	c.x = clamp(c.x, 0, board_size - 1)
	c.y = clamp(c.y, 0, board_size - 1)
	return c


func _snap_all_pieces_to_grid() -> void:
	for child in $Pieces.get_children():
		if child is Piece:
			var local_pos := to_local(child.global_position)
			var c: Vector2i = position_to_coord(local_pos)
			child.coord = c
			child.position = coord_to_position(c)


#debug
func _rebuild_index() -> void:
	_piece_index.clear()
	for child in $Pieces.get_children():
		if child is Piece:
			if _piece_index.has(child.coord):
				if debug_mode:
					push_error("[Board] Dos piezas en la misma coord " + str(child.coord) +
							   " -> " + str(_piece_index[child.coord].name) + " y " + str(child.name))
			_piece_index[child.coord] = child


func _validate_unique_coords() -> void:
	var seen := {}
	for child in $Pieces.get_children():
		if child is Piece:
			if seen.has(child.coord):
				push_error("[Board] DUPLICATE coord " + str(child.coord) + " ocupadas por " +
						   str(seen[child.coord].name) + " y " + str(child.name))
			else:
				seen[child.coord] = child

func _debug_dump_board() -> void:
	print("--- BOARD DUMP ---")
	for y in range(board_size):
		var row := ""
		for x in range(board_size):
			var c := Vector2i(x, y)
			var p : Piece = _piece_index.get(c, null)
			if p:
				var ch := "w" if p.color == Piece.PieceColor.WHITE else "b"
				row += ch
			else:
				row += "."
		print(str(y) + " | " + row)
	print("------------------")


func select_piece(p: Piece) -> void:
	clear_selection()
	_selected_piece = p
	_legal_moves = p.get_moves(self)
	_highlight_moves(_legal_moves)


func clear_selection() -> void:
	_selected_piece = null
	_legal_moves.clear()
	for t in _tiles.values():
		t.set_highlight(false)


func get_legal_moves() -> Array[Vector2i]:
	return _legal_moves


func _color_str(c: int) -> String:
	return "WHITE" if c == Piece.PieceColor.WHITE else "BLACK"

# Muestra en cada Tile el coord y el ocupante (requiere un Label opcional en Tile, ver abajo)
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
