extends ProgressBar
class_name HealthBar

func _ready() -> void:
	# The bar is filled from left to right
	fill_mode = FILL_BEGIN_TO_END
	
	# Hide the percentage text
	show_percentage = false
	
	# Set a default size
	custom_minimum_size = Vector2(60, 10)

func update_bar(current_val: float, max_val: float) -> void:
	if max_val > 0:
		self.max_value = max_val
		self.value = current_val
	else:
		self.max_value = 1
		self.value = 0
