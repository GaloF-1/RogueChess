class_name Player
extends Node

signal gold_changed(new_gold_amount: int)

@export var starting_gold: int = 10

var gold: int:
	get:
		return gold
	set(value):
		if gold != value:
			gold = value
			gold_changed.emit(gold)

func _ready() -> void:
	self.gold = starting_gold


func can_spend(amount: int) -> bool:
	return gold >= amount


func add_gold(amount: int) -> void:
	self.gold += amount
	print("[Player] Oro añadido: ", amount, " | Total: ", gold)


func spend_gold(amount: int) -> bool:
	if can_spend(amount):
		self.gold -= amount
		print("[Player] Oro gastado: ", amount, " | Restante: ", gold)
		return true
	else:
		print("[Player] Intento de gasto fallido. Oro insuficiente.")
		return false
