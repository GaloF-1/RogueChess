@tool
extends Node2D

var _is_dark := false
var _size := 64
var _base_color: Color
var _is_highlighted := false
var _is_selected := false

@export var is_dark: bool = false:
	set(value):
		if _is_dark == value: return
		_is_dark = value
		_base_color = color_dark if value else color_light
		if is_inside_tree(): 
			_apply_visual() 
		else: call_deferred("_apply_visual")
	get: return _is_dark

@export var size: int = 64:
	set(value):
		if _size == value: return
		_size = value
		if is_inside_tree(): 
			_apply_visual() 
		else: call_deferred("_apply_visual")
	get: return _size

@export var cell: Vector2i = Vector2i.ZERO
@export var color_light: Color = Color(0.90, 0.90, 0.90):
	set(value):
		color_light = value
		if !_is_dark: _base_color = value
		if is_inside_tree(): 
			_apply_visual() 
		else: call_deferred("_apply_visual")
@export var color_dark: Color  = Color(0.18, 0.22, 0.35):
	set(value):
		color_dark = value
		if _is_dark: _base_color = value
		if is_inside_tree(): 
			_apply_visual() 
		else: call_deferred("_apply_visual")
@export var highlight_color: Color = Color(1.0, 1.0, 0.0, 0.35)

@onready var rect: ColorRect = $ColorRect
@onready var hitbox: Area2D = $Area2D
@onready var shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ensure_refs() -> void:
	if rect == null: rect = get_node_or_null("ColorRect")
	if hitbox == null: hitbox = get_node_or_null("Area2D")
	if shape == null and hitbox: shape = hitbox.get_node_or_null("CollisionShape2D")

func _enter_tree() -> void:
	_base_color = color_dark if _is_dark else color_light

func _ready() -> void:
	_apply_visual()
	if hitbox:
		hitbox.mouse_entered.connect(func(): emit_signal("hovered", cell))
		hitbox.mouse_exited.connect(func(): emit_signal("exited", cell))
		hitbox.input_event.connect(_on_hitbox_input)

func _apply_visual() -> void:
	_ensure_refs()
	if rect == null: return

	rect.size = Vector2(_size, _size)
	rect.position = Vector2.ZERO

	if shape:
		var r := RectangleShape2D.new()
		r.size = Vector2(_size, _size)
		shape.shape = r
		shape.position = Vector2(_size, _size) * 0.5

	var color_to_use := _base_color
	if _is_selected:
		color_to_use = _base_color.lerp(Color(0.2, 0.8, 1.0), 0.6)
	elif _is_highlighted:
		color_to_use = highlight_color
	rect.color = color_to_use

func _on_hitbox_input(viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", cell)
