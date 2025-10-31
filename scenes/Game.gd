extends Node2D

@onready var board = $Board
@onready var shop_ui = $ShopUI

func _ready() -> void:
	# Center the board
	var screen_size = get_viewport_rect().size
	var board_size_pixels = Vector2(board.board_size * board.tile_px, board.board_size * board.tile_px)
	board.position = (screen_size - board_size_pixels) / 2

	# Position the shop UI
	var padding = 130
	shop_ui.position = Vector2(board.position.x + board_size_pixels.x + padding, board.position.y)

	print("Escena principal del juego 'Game.tscn' cargada.")
