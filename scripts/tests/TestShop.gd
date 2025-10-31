extends Node

@onready var shop: Shop = $ShopUI/Shop

func _ready() -> void:
	# Cargamos los blueprints dinámicamente para evitar errores de dependencias circulares
	var pawn_bp = load("res://assets/blueprints/pawn_blueprint.tres")
	var rook_bp = load("res://assets/blueprints/test_rook_blueprint.tres")
	var king_bp = load("res://assets/blueprints/test_king_blueprint.tres")

	# Asignamos los blueprints al array de la tienda.
	# Esto es lo que haríamos manualmente en el Inspector, pero aquí es automático.
	shop.all_blueprints = [pawn_bp, rook_bp, king_bp]
	
	# Damos algo de oro al jugador para que pueda comprar
	if not Player.has_meta("initialized_for_test"):
		Player.gold = 50
		Player.set_meta("initialized_for_test", true)
	
	# Forzamos a la tienda a generar las ofertas con los blueprints que le dimos
	shop.generate_offers()
	print("Test scene initialized. Player has 50 gold. Shop is ready.")
