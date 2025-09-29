@tool
extends Node2D

# Asigna tu escena de tile aquí (o arrástrala por Inspector si preferís)
@export var tile_scene: PackedScene = preload("res://scenes/BoardTile.tscn")

@export var board_size: int = 8:
	set(v):
		v = max(1, v)
		if board_size == v: return
		board_size = v
		if is_inside_tree():
			_build_board() 
		else: call_deferred("_build_board")

@export var cell_size: int = 64:
	set(v):
		v = max(4, v)
		if cell_size == v: return
		cell_size = v
		if is_inside_tree(): 
			_relayout()
		else: call_deferred("_relayout")

@export var centered: bool = true:
	set(v):
		centered = v
		if is_inside_tree():
			_relayout()
		else: call_deferred("_relayout")

@onready var tiles_node: Node2D = $Tiles

func _ready() -> void:
	_build_board()

func _build_board() -> void:
	if tiles_node == null:
		push_error("Falta el hijo Node2D llamado 'Tiles' en Board.tscn")
		return
	if tile_scene == null:
		push_error("tile_scene no asignado (PackedScene)")
		return

	# Limpia lo previo
	for c in tiles_node.get_children():
		c.queue_free()

	var origin := _origin_offset()
	var count := 0

	# IMPORTANTE: usar range() garantiza la iteración 0..n-1
	for row in range(board_size):
		for col in range(board_size):
			var t := tile_scene.instantiate()
			tiles_node.add_child(t)
			t.name = "Tile_%d_%d" % [col, row]
			t.position = origin + Vector2(col * cell_size, row * cell_size)

			# alterna: claro/oscuro por paridad
			var dark: bool = (((row + col) & 1) == 1)

			# 1) fijá props (disparan setters en BoardTile)
			t.set("cell", Vector2i(col, row))
			t.set("is_dark", dark)

			# 2) aplicá tamaño (usa tu método si querés mantenerlo)
			if t.has_method("setup"):
				t.setup(Vector2i(col, row), dark, cell_size)
			else:
				t.set("size", cell_size)


	print("Board creado: ", board_size, "x", board_size, " → ", count, " tiles")

func _relayout() -> void:
	if tiles_node == null:
		return

	var origin := _origin_offset()

	for child in tiles_node.get_children():
		var t := child                       # alias
		if not t.has_method("setup"):
			continue

		# lee la celda desde la tile
		var cell = t.get("cell")
		if typeof(cell) != TYPE_VECTOR2I:
			continue
		var cell_v: Vector2i = cell

		# reposiciona según el nuevo cell_size / centrado
		t.position = origin + Vector2(cell_v.x * cell_size, cell_v.y * cell_size)

		# alternancia (o respeta is_dark si la tile lo sobreescribe)
		var dark: bool = (((cell_v.x + cell_v.y) & 1) == 1)
		var v = t.get("is_dark")
		if typeof(v) == TYPE_BOOL:
			dark = v

		# aplica color y tamaño
		t.set("is_dark", dark)               # dispara el setter de la tile
		t.setup(cell_v, dark, cell_size)     # asegura size/colisión/visual



func _origin_offset() -> Vector2:
	return -Vector2(board_size * cell_size, board_size * cell_size) * 0.5 if centered else Vector2.ZERO
