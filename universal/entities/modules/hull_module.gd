extends "res://entities/modules/module_base.gd"
class_name HullModule

func _init() -> void:
	module_id = Constants.MODULE_HULL
	grid_size = Vector2i(1, 1)
	metal_cost = Constants.MODULE_COST_METAL[Constants.MODULE_HULL]
	sprite_color = Color(0.2, 0.6, 0.8, 1.0) # Синий цвет корпуса
