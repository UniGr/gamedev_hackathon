extends Node
class_name GridManager

const GRID_WIDTH = 12
const GRID_HEIGHT = 20
const CELL_SIZE = 90

var grid: Dictionary = {}

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	# Инициализация сетки для корабля
	pass

func has_adjacent_module(grid_pos: Vector2i) -> bool:
	# Массив направлений (Верх, Низ, Лево, Право)
	var directions = [
		Vector2i(0, -1), 
		Vector2i(0, 1),  
		Vector2i(-1, 0), 
		Vector2i(1, 0)   
	]
	
	for dir in directions:
		var neighbor_pos = grid_pos + dir
		if grid.has(neighbor_pos):
			return true 
	return false

func is_cell_empty(pos: Vector2i) -> bool:
	return not grid.has(pos)

func can_build_at(grid_pos: Vector2i) -> bool:
	return is_cell_empty(grid_pos) and has_adjacent_module(grid_pos)
	
func set_cell(pos: Vector2i, entity: Node) -> void:
	grid[pos] = entity

func get_cell(pos: Vector2i) -> Node:
	return grid.get(pos)
