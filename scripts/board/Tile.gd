extends Area2D
class_name Tile

signal clicked(coord: Vector2i)

var coord: Vector2i
var size_px: int = 64
var _base_color: Color
@onready var _shape: RectangleShape2D = $CollisionShape2D.shape
@onready var _label: Label = get_node_or_null("OverlayLabel")

func _ready() -> void:
	var rect = get_node("ColorRect")
	if rect:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.position = Vector2.ZERO
		rect.size = Vector2(size_px, size_px)
	else:
		push_error("Tile ", coord, ": ColorRect node not found in _ready!")

	if _shape:
		_shape.size = Vector2(size_px, size_px)
		$CollisionShape2D.position = Vector2(size_px / 2, size_px / 2)
	else:
		push_error("Tile ", coord, " no tiene CollisionShape2D válido")

	if _label == null:
		_label = Label.new()
		_label.name = "OverlayLabel"
		add_child(_label)
		_label.position = Vector2(4, 2)
		_label.scale = Vector2(0.9, 0.9)
		_label.modulate = Color(0, 0, 0)
	
	monitoring = false

func set_overlay_text(t: String) -> void:
	if _label:
		_label.text = t

func set_checker_color(is_light: bool, light: Color, dark: Color) -> void:
	_base_color = light if is_light else dark
	var rect = get_node("ColorRect")
	if rect:
		rect.color = _base_color
	else:
		push_error("Tile ", coord, ": ColorRect not found in set_checker_color!")

func set_highlight(active: bool) -> void:
	var rect = get_node("ColorRect")
	if rect:
		rect.color = _base_color.lerp(Color.YELLOW, 0.35) if active else _base_color
	else:
		push_error("Tile ", coord, ": ColorRect not found in set_highlight!")
	
	monitoring = active

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(coord)
