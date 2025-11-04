extends Node2D
class_name Piece

enum PieceColor { WHITE, BLACK }

@export var color: PieceColor = PieceColor.WHITE:
	set(value):
		if color != value:
			color = value
			_apply_sprite()
@export var sprite_white: Texture2D
@export var sprite_black: Texture2D
@export var draggable: bool = true
@export var initial_coord: Vector2i = Vector2i(-1, -1)

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _hitbox: Area2D = get_node_or_null("Hitbox")
@onready var _shape: RectangleShape2D = _hitbox.get_node("CollisionShape2D").shape if _hitbox else null

#region Stats RPG
var blueprint: PieceBlueprint
var max_hp: int = 10
var current_hp: int = 10
var attack_damage: int = 1
var defense: int = 0
var attack_speed: float = 1.0
var attack_range: int = 1
var crit_chance: float = 0.05
var crit_damage_multiplier: float = 1.5
#endregion

var _dragging := false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_coord: Vector2i
var coord: Vector2i = Vector2i(0, 0):
	get: return coord
	set(value):
		var old = coord
		coord = value
		var board := _get_board()
		if board:
			board._on_piece_coord_changed(self, old, value)
			position = board.coord_to_position(value)

var _drag_start_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 5.0

func _ready() -> void:
	if initial_coord.x >= 0 and initial_coord.y >= 0:
		coord = initial_coord
	y_sort_enabled = true
	z_index = 1
	_apply_sprite()
	_snap_to_board()
	_setup_hitbox()
	set_process_input(true)

func apply_blueprint(bp: PieceBlueprint) -> void:
	self.blueprint = bp
	self.name = bp.piece_name
	self.max_hp = bp.max_hp
	self.current_hp = bp.max_hp
	self.attack_damage = bp.attack_damage
	self.defense = bp.defense
	self.attack_speed = bp.attack_speed
	self.attack_range = bp.attack_range
	self.crit_chance = bp.crit_chance
	self.crit_damage_multiplier = bp.crit_damage_multiplier

func _setup_hitbox() -> void:
	if not _hitbox: push_error("[Piece] Falta un Area2D llamado 'Hitbox'"); return
	var board: Board = _get_board()
	if _shape and board: _shape.size = Vector2(board.tile_px, board.tile_px)
	if not _hitbox.input_event.is_connected(_on_hitbox_input):
		_hitbox.input_event.connect(_on_hitbox_input)

func _on_hitbox_input(viewport, event, shape_idx) -> void:
	if not draggable or not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		var board := _get_board()
		# En modo combate, solo el turno actual puede mover. En modo arreglo, solo el color del jugador.
		if board and board.is_arrangement_mode and self.color != board.arrangement_color:
			return
		if board and not board.is_arrangement_mode and self.color != board.current_turn:
			return
		
		_drag_start_pos = get_global_mouse_position()
		_drag_start_coord = coord
		z_index = 100
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if z_index <= 1: return

	if event is InputEventMouseMotion and not _dragging:
		if _drag_start_pos.distance_to(get_global_mouse_position()) >= DRAG_THRESHOLD:
			_start_drag()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()

func _start_drag() -> void:
	var board: Board = _get_board()
	if not board or board._moving: return
		
	_dragging = true
	_drag_offset = global_position - get_global_mouse_position()
	z_index = 1000
	
	# Solo mostrar movimientos legales en modo combate
	if not board.is_arrangement_mode:
		board.select_piece(self)

func _process(delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset

func _end_drag() -> void:
	var board: Board = _get_board()
	var was_a_drag = _dragging

	_dragging = false
	z_index = 1

	if not board: 
		if is_instance_valid(self): position = board.coord_to_position(_drag_start_coord)
		return

	if was_a_drag:
		var target_coord := board.position_to_coord(board.to_local(global_position))
		
		if board.is_arrangement_mode:
			# Lógica de Fase de Organización
			if self.color == board.arrangement_color and board.is_valid_arrangement_square(target_coord) and board.get_piece_at(target_coord) == null:
				self.coord = target_coord
			else:
				# Movimiento inválido, volver a la posición original
				self.coord = _drag_start_coord
		else:
			# Lógica de Fase de Combate (la original)
			if target_coord in board.get_legal_moves():
				board.move_piece_to(self, target_coord)
			# Si no, la pieza vuelve sola porque no se actualiza su 'coord'
	else:
		# Fue un clic, no un arrastre. Solo relevante en modo combate.
		if not board.is_arrangement_mode:
			board.select_piece(self)

	# Al final, asegurar que la posición visual coincida con la coordenada lógica.
	if is_instance_valid(self):
		position = board.coord_to_position(coord)

func get_moves(board: Board) -> Array[Vector2i]:
	return []

func _apply_sprite() -> void:
	if not _sprite: push_error("[Piece] Falta un hijo Sprite2D."); return
	var tex: Texture2D = sprite_white if color == PieceColor.WHITE else sprite_black
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.position = Vector2.ZERO

	var board: Board = _get_board()
	if board and tex and tex.get_size().x > 0 and tex.get_size().y > 0:
		var target_size := board.tile_px * 0.7
		var scale_factor = target_size / max(tex.get_size().x, tex.get_size().y)
		_sprite.scale = Vector2(scale_factor, scale_factor)

func _snap_to_board() -> void:
	var board: Board = _get_board()
	if board: position = board.coord_to_position(coord)

func _get_board() -> Board:
	var n = get_parent()
	while n:
		if n is Board: return n
		n = n.get_parent()
	return null

func _color_str(c: int) -> String:
	return "WHITE" if c == PieceColor.WHITE else "BLACK"
