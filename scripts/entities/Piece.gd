extends Node2D
class_name Piece

const DARKEN_SHADER = preload("res://scripts/shaders/darken.gdshader")

signal defeated(victim: Piece, killer: Piece)

enum PieceColor { WHITE, BLACK }

@export var color: PieceColor = PieceColor.WHITE:
	set(value):
		if color != value:
			color = value
			_apply_sprite()
@export var sprite_white: Texture2D
@export var sprite_black: Texture2D
@export var battle_sprite_frames: SpriteFrames
@export var draggable: bool = true
@export var initial_coord: Vector2i = Vector2i(-1, -1)

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _battle_sprite: AnimatedSprite2D = get_node_or_null("BattleSprite")
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

	# Ensure correct sprite visibility on load
	if _sprite: _sprite.visible = true
	if _battle_sprite: _battle_sprite.visible = false

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

# --- COMBAT --- 

enum BattleState { IDLE, ATTACKING }

var battle_state = BattleState.IDLE
var opponents: Array = []
var current_target: Piece = null
var attack_cooldown: float = 0.0

func begin_combat(opponents_list: Array) -> void:
	self.opponents = opponents_list
	
	# Switch to battle sprite
	if _sprite: _sprite.visible = false
	if _battle_sprite:
		_battle_sprite.visible = true
		_battle_sprite.sprite_frames = battle_sprite_frames
		_battle_sprite.play("idle")

		# Flip sprite if it's a black piece
		if color == PieceColor.BLACK:
			_battle_sprite.flip_h = true
			# Apply darken shader
			var material = ShaderMaterial.new()
			material.shader = DARKEN_SHADER
			_battle_sprite.material = material
	
	# Find initial target
	self.current_target = _find_closest_opponent()
	
	# Start processing combat logic
	set_process(true)

func _process(delta: float) -> void:
	# Dragging logic from before
	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset
		return # Don't process combat while dragging
	
	if battle_state == BattleState.IDLE and not is_instance_valid(current_target):
		current_target = _find_closest_opponent()
		return
	
	# --- Main Combat Logic ---
	attack_cooldown -= delta

	# Check if target is still valid
	if not is_instance_valid(current_target):
		battle_state = BattleState.IDLE
		current_target = _find_closest_opponent()
		if _battle_sprite: _battle_sprite.play("idle")
		return

	# If we have a valid target, we are always attacking
	battle_state = BattleState.ATTACKING

	if attack_cooldown <= 0.0:
		if _battle_sprite: _battle_sprite.play("attack")
		_attack(current_target)
		# Reset cooldown based on attack speed (attacks per second)
		attack_cooldown = 1.0 / attack_speed


func take_damage(amount: int, killer: Piece = null) -> void:
	var damage_taken = max(0, amount - defense)
	self.current_hp -= damage_taken
	print(name, " takes ", damage_taken, " damage, ", current_hp, " HP left.")

	if self.current_hp <= 0:
		print(name, " has been defeated.")
		defeated.emit(self, killer)

func _find_closest_opponent() -> Piece:
	var closest = null
	var min_dist = INF
	for opponent in opponents:
		if not is_instance_valid(opponent): continue
		var dist = self.global_position.distance_squared_to(opponent.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = opponent
	return closest

func _attack(target: Piece) -> void:
	print(name, " attacks ", target.name)
	target.take_damage(self.attack_damage, self)

func end_combat() -> void:
	if _sprite: _sprite.visible = true
	if _battle_sprite:
		_battle_sprite.visible = false
		_battle_sprite.stop()
		_battle_sprite.frame = 0 # Reset animation frame
		_battle_sprite.material = null # Remove shader
		_battle_sprite.flip_h = false # Reset flip
	
	# Reactivate input for drag and drop
	set_process_input(true)
	_setup_hitbox()

	battle_state = BattleState.IDLE
	opponents = []
	current_target = null
	attack_cooldown = 0.0
