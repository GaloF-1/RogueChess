extends Node2D

# Rutas a tus escenas
const BOARD_SCENE := preload("res://scenes/Board.tscn")
const TILE_SCENE  := preload("res://scenes/BoardTile.tscn") # por si tu Board no lo pre-carga

@onready var cam: Camera2D = $Camera2D
var board: Node = null

func _ready() -> void:
	# 1) Instanciar el tablero
	board = BOARD_SCENE.instantiate()
	add_child(board)
	board.name = "Board"

	# 2) Asegurar que Board tiene su tile_scene asignada
	if board.has_method("set") and board.get("tile_scene") == null:
		board.set("tile_scene", TILE_SCENE)

	# 3) Config inicial (usa tus exports)
	if board.has_method("set"):
		board.set("board_size", 8)   # NxN
		board.set("cell_size", 64)   # px por celda
		board.set("centered", true)  # centrado en (board.position)

	# 4) Posicionar el tablero en el centro de la pantalla
	var view_size := get_viewport_rect().size
	board.position = view_size * 0.5

	# 5) Forzar construcción (por si tu Board no se auto-construye en _ready)
	if board.has_method("_build_board"):
		board.call("_build_board")

	# 6) Cámara (opcional, pero cómodo)
	if cam:
		cam.position = view_size * 0.5
		cam.enabled = true
		# cam.zoom = Vector2(0.75, 0.75)  # acercar (opcional)

	# 7) Debug: contá tiles
	var tiles := board.get_node_or_null("Tiles")
	if tiles:
		print("Tiles instanciadas: ", tiles.get_child_count())
	else:
		push_warning("El Board no tiene hijo 'Tiles'. Verificá tu Board.tscn")


func _unhandled_input(event):
	if event.is_action_pressed("ui_up"):
		board.set("board_size", board.get("board_size") + 2)
		board.call("_build_board")
	if event.is_action_pressed("ui_down"):
		board.set("board_size", max(2, board.get("board_size") - 2))
		board.call("_build_board")
