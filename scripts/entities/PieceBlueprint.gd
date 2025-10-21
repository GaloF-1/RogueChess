class_name PieceBlueprint
extends Resource

@export var piece_scene: PackedScene
@export var texture: Texture2D
@export var piece_name: String = ""
@export var cost: int = 5
@export var max_hp: int = 10
@export var attack_damage: int = 2
@export var defense: int = 0

@export_group("Secondary Stats")
@export var attack_speed: float = 1.0 # Ataques por segundo
@export var attack_range: int = 1 # En casillas
@export var crit_chance: float = 0.05 # 5% de probabilidad
@export var crit_damage_multiplier: float = 1.5 # 150% de daño


# Función para crear una instancia de la pieza en el tablero
func instantiate() -> Piece:
	if not piece_scene or not piece_scene.can_instantiate():
		push_error("PieceBlueprint: La escena de la pieza no es válida.")
		return null
	
	var piece_instance: Piece = piece_scene.instantiate() as Piece
	if not piece_instance:
		push_error("La escena instanciada no es de tipo Piece.")
		return null
	
	# Aplicamos los datos del blueprint a la nueva instancia
	piece_instance.apply_blueprint(self)
	
	return piece_instance
