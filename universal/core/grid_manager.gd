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

func is_cell_empty(pos: Vector2) -> bool:
	return not grid.has(pos)

func set_cell(pos: Vector2, entity: Node) -> void:
	grid[pos] = entity

func get_cell(pos: Vector2) -> Node:
	return grid.get(pos)
