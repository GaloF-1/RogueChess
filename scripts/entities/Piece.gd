extends Node2D
class_name Piece

enum PieceColor { WHITE, BLACK }

@export var color: PieceColor = PieceColor.WHITE
@export var sprite_white: Texture2D
@export var sprite_black: Texture2D
@export var draggable: bool = true

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _hitbox: Area2D = get_node_or_null("Hitbox")
@onready var _shape: RectangleShape2D = _hitbox.get_node("CollisionShape2D").shape if _hitbox else null

var _dragging := false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_coord: Vector2i
var _drag_current_coord: Vector2i = coord
var _coord: Vector2i = Vector2i(0, 0)

@export var coord: Vector2i:
	get:
		return _coord
	set(value):
		var old := _coord
		_coord = value
		var board := _get_board()
		if board:
			board._on_piece_coord_changed(self, old, value)  # mantiene el índice
			position = board.coord_to_position(value)        # snap visual


func _start_drag() -> void:
	var board: Board = _get_board()
	if not board or board._moving or not draggable:
		return
	_dragging = true
	_drag_start_coord = coord
	_drag_current_coord = coord
	_drag_offset = global_position - get_global_mouse_position()
	z_index = 1000
	if board:
		board.select_piece(self)

func _process(_delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset
		var board: Board = _get_board()
		if board:
			_drag_current_coord = board.position_to_coord(board.to_local(global_position))

func _end_drag() -> void:
	if not is_inside_tree() or not is_instance_valid(self) or process_mode == PROCESS_MODE_DISABLED:
		_dragging = false
		return
	_dragging = false
	z_index = 1
	var board: Board = _get_board()
	if not board:
		position = board.coord_to_position(_drag_start_coord)
		return

	var target: Vector2i = _drag_current_coord
	board._rebuild_index()  # Forzar sincronización antes de calcular movimientos
	var occ_before: Piece = board.get_piece_at(target)
	var legal := get_moves(board)
	var is_legal := target in legal

	print("[DROP] ", name, " ", _color_str(color), " from=", _drag_start_coord, " -> ", target,
		  " | legal=", is_legal, " | occ_before=",(occ_before.name + " " + _color_str(occ_before.color)) if occ_before else "None")

	if is_legal:
		board.move_piece_to(self, target)
	else:
		coord = _drag_start_coord
		position = board.coord_to_position(_drag_start_coord)

	board.clear_selection()
	if _hitbox:
		_hitbox.monitoring = false  # Desactivar hitbox tras drop


func _ready() -> void:
	print("Piece ", name, " color=", "WHITE" if color == PieceColor.WHITE else "BLACK", " coord=", coord)
	y_sort_enabled = true
	z_index = 1
	_apply_sprite()
	_snap_to_board()
	_setup_hitbox()

func _setup_hitbox() -> void:
	if _hitbox == null:
		push_error("[Piece] Falta un Area2D llamado 'Hitbox'")
		return
	var board: Board = _get_board()
	if _shape and board:
		_shape.size = Vector2(board.tile_px, board.tile_px)
	# Conectar input del Area2D
	if not _hitbox.input_event.is_connected(_on_hitbox_input):
		_hitbox.input_event.connect(_on_hitbox_input)


func _on_hitbox_input(viewport, event, shape_idx) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()


func _color_str(c: int) -> String:
	return "WHITE" if c == PieceColor.WHITE else "BLACK"


func _apply_sprite() -> void:
	if _sprite == null:
		push_error("[Piece] Falta un hijo Sprite2D (ruta: 'Sprite2D').")
		return
	var tex: Texture2D = sprite_white if color == PieceColor.WHITE else sprite_black
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.position = Vector2.ZERO

	var board: Board = _get_board()
	if board and tex:
		var tex_size: Vector2 = tex.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var target := board.tile_px * 0.7
			var s = target / max(tex_size.x, tex_size.y)
			_sprite.scale = Vector2(s, s)

func _snap_to_board() -> void:
	var board: Board = _get_board()
	if board:
		position = board.coord_to_position(coord)

func _get_board() -> Board:
	var n := get_parent()
	while n:
		if n is Board:
			return n
		n = n.get_parent()
	return null

func get_moves(board: Board) -> Array[Vector2i]:
	return []  # virtual, las hijas implementan
