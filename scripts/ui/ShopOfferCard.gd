class_name ShopOfferCard
extends PanelContainer

@onready var piece_texture: TextureRect = $%PieceTexture
@onready var name_label: Label = $%NameLabel
@onready var cost_label: Label = $%CostLabel
@onready var stats_label: Label = $%StatsLabel
@onready var buy_button: Button = $%BuyButton

var blueprint: PieceBlueprint
var shop: Shop

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

# Esta función es llamada por la UI principal para configurar la tarjeta
func setup(bp: PieceBlueprint, s: Shop) -> void:
	self.blueprint = bp
	self.shop = s
	
	# Actualizar los textos y la imagen de la UI
	piece_texture.texture = bp.texture
	print("Blueprint texture: ", bp.texture)
	print("PieceTexture node texture: ", piece_texture.texture)
	name_label.text = bp.piece_name
	cost_label.text = str(bp.cost) + " Oro"
	stats_label.text = "HP: %d | ATK: %d | DEF: %d" % [bp.max_hp, bp.attack_damage, bp.defense]


func _on_buy_pressed() -> void:
	if not blueprint or not shop:
		return

	# Intentar comprar el objeto a través de la tienda principal
	var purchased_bp = shop.purchase(blueprint)
	
	if purchased_bp:
		# Si la compra tiene éxito, el objeto ya no está disponible.
		# La UI principal se encargará de refrescar las ofertas, pero podemos
		# deshabilitar el botón para dar feedback inmediato.
		buy_button.disabled = true
		buy_button.text = "Comprado"
