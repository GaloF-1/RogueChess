class_name ShopOfferCard
extends PanelContainer

@onready var piece_texture: TextureRect = $%PieceTexture
@onready var name_label: Label = $%NameLabel
@onready var cost_label: Label = $%CostLabel
@onready var stats_label: Label = $%StatsLabel
@onready var buy_button: Button = $%BuyButton

var blueprint: PieceBlueprint
var shop: Shop

var _is_dragging := false
var _ghost_piece: Node2D = null

func _ready() -> void:
	#buy_button.visible = false
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		elif _is_dragging:
			_end_drag()
	
	if event is InputEventMouseMotion and _is_dragging:
		_on_drag()

func _start_drag() -> void:
	if not Player.can_spend(blueprint.cost):
		return

	_is_dragging = true
	
	_ghost_piece = Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = blueprint.texture
	sprite.centered = true
	
	var tile_size = 64.0
	var tex_size = sprite.texture.get_size()
	var scale = tile_size * 0.7 / max(tex_size.x, tex_size.y)
	sprite.scale = Vector2(scale, scale)
	
	_ghost_piece.add_child(sprite)
	_ghost_piece.name = "GhostPiece"
	get_tree().root.add_child(_ghost_piece)
	
	_ghost_piece.global_position = get_global_mouse_position()

func _on_drag() -> void:
	if _ghost_piece:
		_ghost_piece.global_position = get_global_mouse_position()

func _end_drag() -> void:
	_is_dragging = false

	var board: Board = get_tree().get_first_node_in_group("board")
	
	if board:
		var target_coord := board.position_to_coord(board.to_local(get_global_mouse_position()))
		# La colocación es válida si es una casilla de organización del jugador y está vacía.
		var is_valid_placement := board.is_valid_arrangement_square(target_coord) and board.is_coord_empty(target_coord)

		if is_valid_placement:
			var purchased_bp = shop.purchase(blueprint)
			if purchased_bp:
				# Llamada corregida con el color de la pieza.
				board.place_new_piece(purchased_bp, target_coord, Piece.PieceColor.WHITE)
		else:
			print("[ShopCard] Colocación inválida en la casilla: ", target_coord)
	
	if is_instance_valid(_ghost_piece):
		_ghost_piece.queue_free()
	_ghost_piece = null

func setup(bp: PieceBlueprint, s: Shop) -> void:
	self.blueprint = bp
	self.shop = s
	
	piece_texture.texture = bp.texture
	name_label.text = bp.piece_name
	cost_label.text = str(bp.cost) + " Oro"
	stats_label.text = "HP: %d | ATK: %d | DEF: %d" % [bp.max_hp, bp.attack_damage, bp.defense]
