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
	# Ya no usamos el botón de comprar, la tarjeta entera es interactiva.
	# La conexión se deja por si el botón sigue en la escena, pero no hará nada.
	buy_button.pressed.disconnect(_on_buy_pressed)
	buy_button.visible = false # Ocultamos el botón

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		elif _is_dragging:
			_end_drag()
	
	if event is InputEventMouseMotion and _is_dragging:
		_on_drag()

func _start_drag() -> void:
	if not PlayerLoad.can_spend(blueprint.cost):
		print("[ShopCard] Oro insuficiente para iniciar arrastre.")
		# TODO: Añadir feedback visual (ej. vibración)
		return

	print("[ShopCard] Iniciando arrastre para ", blueprint.piece_name)
	_is_dragging = true
	
	# Crear la pieza fantasma
	_ghost_piece = Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = blueprint.texture
	sprite.centered = true
	# Escalar el sprite para que coincida con el tamaño de las piezas en el tablero
	# Este valor puede necesitar ajuste.
	var tile_size = 64.0 # Asumimos 64px, idealmente se obtiene del tablero
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
	print("[ShopCard] Finalizando arrastre.")
	_is_dragging = false

	var board: Board = get_tree().get_first_node_in_group("board")
	
	if board:
		var target_coord := board.position_to_coord(board.to_local(get_global_mouse_position()))
		var is_valid_placement := board.is_coord_empty(target_coord) # Por ahora, cualquier casilla vacía es válida
		
		print("[ShopCard] Drop en coord: ", target_coord, " | Válido: ", is_valid_placement)

		if is_valid_placement:
			# Intentar comprar y luego colocar
			var purchased_bp = shop.purchase(blueprint)
			if purchased_bp:
				board.place_new_piece(purchased_bp, target_coord)
		else:
			print("[ShopCard] Colocación inválida.")
			# TODO: Añadir feedback visual (ej. fantasma en rojo)
	
	# Limpiar la pieza fantasma
	if is_instance_valid(_ghost_piece):
		_ghost_piece.queue_free()
	_ghost_piece = null

# Esta función es llamada por la UI principal para configurar la tarjeta
func setup(bp: PieceBlueprint, s: Shop) -> void:
	self.blueprint = bp
	self.shop = s
	
	# Actualizar los textos y la imagen de la UI
	piece_texture.texture = bp.texture
	name_label.text = bp.piece_name
	cost_label.text = str(bp.cost) + " Oro"
	stats_label.text = "HP: %d | ATK: %d | DEF: %d" % [bp.max_hp, bp.attack_damage, bp.defense]

# La función original del botón ya no es necesaria
func _on_buy_pressed() -> void:
	pass