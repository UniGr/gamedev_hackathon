extends Node
class_name GridManager

const GRID_WIDTH: int = 12
const GRID_HEIGHT: int = 20
const CELL_SIZE: int = 90

var _occupied_cells: Dictionary = {}
var _powered_cells: Dictionary = {}
var _reactor_cells: Array[Vector2i] = []

func reset_grid() -> void:
	_occupied_cells.clear()
	_powered_cells.clear()
	_reactor_cells.clear()

func canBuildAt(pos: Vector2i, module_type: String, size: Vector2i = Vector2i.ONE) -> bool:
	if not _is_area_inside_grid(pos, size):
		return false

	if _is_area_occupied(pos, size):
		return false

	# Важное исправление: разрешаем строить, если ХОТЯ БЫ ОДНА клетка под модулем запитана
	# или если это корпус (Hull), который можно лепить к запитанным
	if not _is_any_cell_powered(pos, size):
		return false

	# Смягчаем проверку реакторов: нельзя ставить реактор прямо на другой реактор (это и так нельзя через occupied),
	# но убираем блокировку соседних клеток, если это мешает геймплею
	# if module_type == Constants.MODULE_REACTOR and _intersects_reactor_zone(pos):
	# 	return false

	return true

func register_core(pos: Vector2i, size: Vector2i, entity: Node) -> void:
	var core_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in core_cells:
		_occupied_cells[cell] = entity
	# Ядро дает питание в радиусе 2 клеток (увеличил)
	_mark_power_around_cells(core_cells, 2)

func register_module(pos: Vector2i, size: Vector2i, module_type: String, entity: Node) -> void:
	var module_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in module_cells:
		_occupied_cells[cell] = entity

	if module_type == Constants.MODULE_REACTOR:
		for cell in module_cells:
			_reactor_cells.append(cell)
		# Реактор дает питание вокруг себя
		_mark_power_around_cells(module_cells, 2)

func unregister_module(entity: Node) -> void:
	var keys_to_remove: Array[Vector2i] = []
	for key in _occupied_cells.keys():
		if _occupied_cells[key] == entity:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_occupied_cells.erase(key)

func get_occupied_cells() -> Dictionary:
	return _occupied_cells.duplicate(true)

func _is_area_inside_grid(pos: Vector2i, size: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and (pos.x + size.x) <= GRID_WIDTH and (pos.y + size.y) <= GRID_HEIGHT

func _is_area_occupied(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			if _occupied_cells.has(Vector2i(x, y)): return true
	return false

func _is_any_cell_powered(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			if _powered_cells.has(Vector2i(x, y)): return true
	return false

func _mark_power_around_cells(cells: Array[Vector2i], radius: int) -> void:
	for source_cell in cells:
		for x in range(source_cell.x - radius, source_cell.x + radius + 1):
			for y in range(source_cell.y - radius, source_cell.y + radius + 1):
				var cell: Vector2i = Vector2i(x, y)
				if cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT:
					_powered_cells[cell] = true

func _collect_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			cells.append(Vector2i(x, y))
	return cells
