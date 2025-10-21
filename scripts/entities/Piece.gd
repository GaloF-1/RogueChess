extends Node2D
class_name Piece

enum PieceColor { WHITE, BLACK }

@export var color: PieceColor = PieceColor.WHITE
@export var sprite_white: Texture2D
@export var sprite_black: Texture2D
@export var draggable: bool = true
@export var initial_coord: Vector2i = Vector2i(-1, -1)  # Coordenadas iniciales manuales

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _hitbox: Area2D = get_node_or_null("Hitbox")
@onready var _shape: RectangleShape2D = _hitbox.get_node("CollisionShape2D").shape if _hitbox else null

#region Stats RPG
var blueprint: PieceBlueprint # Referencia al blueprint original
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
	get:
		return coord
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
	print("[Piece] ", name, " color=", _color_str(color), " coord=", coord)
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
	
	# Asignar stats desde el blueprint
	self.name = bp.piece_name
	self.max_hp = bp.max_hp
	self.current_hp = bp.max_hp # La vida actual empieza al máximo
	self.attack_damage = bp.attack_damage
	self.defense = bp.defense
	self.attack_speed = bp.attack_speed
	self.attack_range = bp.attack_range
	self.crit_chance = bp.crit_chance
	self.crit_damage_multiplier = bp.crit_damage_multiplier
	
	print("[Piece] Blueprint aplicado a ", self.name, ": HP=", self.max_hp, ", ATK=", self.attack_damage)

func _setup_hitbox() -> void:
	if _hitbox == null:
		push_error("[Piece] Falta un Area2D llamado 'Hitbox'")
		return
	var board: Board = _get_board()
	if _shape and board:
		_shape.size = Vector2(board.tile_px, board.tile_px)
	if not _hitbox.input_event.is_connected(_on_hitbox_input):
		_hitbox.input_event.connect(_on_hitbox_input)

func _on_hitbox_input(viewport, event, shape_idx) -> void:
	if not draggable or not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		_drag_start_pos = get_global_mouse_position()
		_drag_start_coord = coord
		z_index = 100 # "Levantamos" la pieza para indicar que está lista para ser arrastrada.
		get_viewport().set_input_as_handled() # Prevenimos que otros elementos procesen este clic.

func _input(event: InputEvent) -> void:
	if z_index <= 1: # Solo procesamos eventos si la pieza está "levantada"
		return

	if event is InputEventMouseMotion and not _dragging:
		if _drag_start_pos.distance_to(get_global_mouse_position()) >= DRAG_THRESHOLD:
			_start_drag()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()

func _start_drag() -> void:
	var board: Board = _get_board()
	if not board or board._moving:
		return
		
	print("[Piece] Iniciando arrastre en ", name)
	_dragging = true
	_drag_offset = global_position - get_global_mouse_position()
	z_index = 1000 # Aumentamos z_index durante el arrastre
	
	board.select_piece(self)

func _process(delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset

func _end_drag() -> void:
	var board: Board = _get_board()
	var was_a_drag = _dragging

	# Resetear estado inmediatamente
	_dragging = false
	z_index = 1

	if not board:
		if is_instance_valid(self):
			position = board.coord_to_position(_drag_start_coord)
		return

	if was_a_drag:
		var target: Vector2i = board.position_to_coord(board.to_local(global_position))
		var legal_moves := get_moves(board)
		var is_legal := target in legal_moves

		if board.debug_mode:
			var occ_before = board.get_piece_at(target)
			print("[DROP] ", name, " ", _color_str(color), " from=", _drag_start_coord, " -> ", target,
				  " | legal=", is_legal, " | occ_before=", (occ_before.name + " " + _color_str(occ_before.color)) if occ_before else "None")

		if is_legal:
			board.move_piece_to(self, target)
		else:
			# Si no es legal, la pieza no se movió lógicamente.
			# El 'coord' no cambió. Solo aseguramos la posición visual.
			pass
	else:
		# Si no hubo arrastre, fue un clic.
		print("[Piece] Clic detectado en ", name, " en coord ", coord)
		board.select_piece(self)

	# Al final de toda la operación, nos aseguramos de que la posición visual
	# corresponda con la coordenada lógica actual de la pieza.
	if is_instance_valid(self):
		position = board.coord_to_position(coord)

func get_moves(board: Board) -> Array[Vector2i]:
	return []

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

func _color_str(c: int) -> String:
	return "WHITE" if c == PieceColor.WHITE else "BLACK"
