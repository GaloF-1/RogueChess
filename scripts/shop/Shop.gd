class_name Shop
extends Node

signal offers_generated(offers: Array[PieceBlueprint])

@export var all_blueprints: Array[PieceBlueprint] = []

@export_group("Shop Settings")
@export var num_offers_per_round: int = 3
@export var reroll_cost: int = 1

var current_offers: Array[PieceBlueprint] = []

func _ready() -> void:
	if all_blueprints.is_empty():
		push_warning("[Shop] La lista de todos los blueprints está vacía. La tienda no podrá generar ofertas.")

# Genera nuevas ofertas y emite una señal con ellas
func generate_offers() -> void:
	current_offers.clear()
	if all_blueprints.is_empty():
		print("[Shop] No se pueden generar ofertas porque no hay blueprints.")
		offers_generated.emit([])
		return

	# Selecciona N blueprints aleatorios sin repetición
	var available_blueprints = all_blueprints.duplicate()
	available_blueprints.shuffle()
	
	var num_to_generate = min(num_offers_per_round, available_blueprints.size())
	for i in range(num_to_generate):
		current_offers.append(available_blueprints[i])
	
	print("[Shop] Nuevas ofertas generadas: ", current_offers)
	offers_generated.emit(current_offers)

# Intenta hacer un reroll, gastando oro del jugador
func reroll() -> void:
	if Player.spend_gold(reroll_cost):
		print("[Shop] Reroll exitoso.")
		generate_offers()
	else:
		print("[Shop] Oro insuficiente para reroll.")

# Intenta comprar un objeto, devuelve el blueprint si tiene éxito
func purchase(blueprint: PieceBlueprint) -> PieceBlueprint:
	if not blueprint in current_offers:
		push_error("[Shop] Se intentó comprar un blueprint que no está en las ofertas actuales.")
		return null

	if Player.spend_gold(blueprint.cost):
		print("[Shop] Compra exitosa de: ", blueprint.piece_name)
		# Eliminamos la oferta comprada de la lista actual
		current_offers.erase(blueprint)
		# Notificamos a los oyentes (como la UI) que las ofertas han cambiado
		offers_generated.emit(current_offers)
		return blueprint
	else:
		print("[Shop] Oro insuficiente para comprar: ", blueprint.piece_name)
		return null
