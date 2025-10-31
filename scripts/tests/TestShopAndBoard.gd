extends Node2D

@onready var board: Board = $Board
@onready var shop_ui: Control = $ShopUI
@onready var shop: Shop = $ShopUI/Shop

func _ready() -> void:
	# 1. Clear the board using the new centralized method
	board.clear_board()

	# 2. Populate the shop with all available blueprints, imitating TestShop.gd
	var pawn_bp = load("res://assets/blueprints/pawn_blueprint.tres")
	var rook_bp = load("res://assets/blueprints/test_rook_blueprint.tres")
	var king_bp = load("res://assets/blueprints/test_king_blueprint.tres")

	shop.all_blueprints = [pawn_bp, rook_bp, king_bp]
	print("[TestScene] Shop blueprints configured.")

	# 3. Give the player some gold for testing
	if not Player.has_meta("initialized_for_test"):
		Player.gold = 50
		Player.set_meta("initialized_for_test", true)
	print("[TestScene] Player gold set to 50 for testing.")

	# 4. Generate initial offers
	shop.generate_offers()
	print("[TestScene] Initial shop offers generated.")
