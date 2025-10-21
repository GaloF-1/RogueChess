class_name ShopUI
extends Control

# Nodos de la escena que asignaremos en el editor
@onready var offers_container: VBoxContainer = $%OffersContainer
@onready var gold_label: Label = $%GoldLabel
@onready var reroll_button: Button = $%RerollButton

# Referencia al nodo de la tienda (asumimos que es un hijo de esta UI o está en un lugar accesible)
@onready var shop: Shop = $Shop

# Escena de la tarjeta que usaremos para instanciar cada oferta
@export var offer_card_scene: PackedScene


func _ready() -> void:
	# Conectar señales para que la UI reaccione a los cambios
	if shop:
		shop.offers_generated.connect(_on_offers_generated)
	
	if PlayerLoad:
		PlayerLoad.gold_changed.connect(_on_gold_changed)
		# Actualizar el oro inicial
		_on_gold_changed(PlayerLoad.gold)
	
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)


# Limpia y crea las nuevas tarjetas de oferta en la UI
func _on_offers_generated(offers: Array[PieceBlueprint]) -> void:
	# Limpiar ofertas anteriores
	for child in offers_container.get_children():
		child.queue_free()
	
	# Instanciar una tarjeta por cada oferta
	if not offer_card_scene:
		push_warning("[ShopUI] No se ha asignado la escena de la tarjeta de oferta (offer_card_scene).")
		return

	for blueprint in offers:
		var card = offer_card_scene.instantiate()
		offers_container.add_child(card)
		# Pasamos el blueprint y la tienda a la tarjeta para que se configure
		card.setup(blueprint, shop)


# Actualiza el texto del oro
func _on_gold_changed(new_gold: int) -> void:
	if gold_label:
		gold_label.text = "Oro: %d" % new_gold


# Maneja el clic en el botón de reroll
func _on_reroll_pressed() -> void:
	if shop:
		shop.reroll()
