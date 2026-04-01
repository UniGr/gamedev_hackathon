extends Node
class_name GridManager
## Менеджер сетки для размещения модулей корабля.
## Отвечает за валидацию позиций, зоны питания и регистрацию модулей.
## Используется как локальный экземпляр в GameBoard.

## Ширина сетки в ячейках.
const GRID_WIDTH: int = 12
## Высота сетки в ячейках.
const GRID_HEIGHT: int = 20
## Размер одной ячейки в пикселях.
const CELL_SIZE: int = 135

## Словарь занятых ячеек: Vector2i -> Node (модуль).
var _occupied_cells: Dictionary = {}
## Словарь ячеек с питанием: Vector2i -> bool.
var _powered_cells: Dictionary = {}
## Ячейки реакторов (источники питания).
var _reactor_cells: Array[Vector2i] = []
## Ячейки ядра (центральный источник питания).
var _core_cells: Array[Vector2i] = []


## Полностью сбрасывает сетку в начальное состояние.
## Полностью сбрасывает сетку в начальное состояние.
func reset_grid() -> void:
	_occupied_cells.clear()
	_powered_cells.clear()
	_reactor_cells.clear()
	_core_cells.clear()


## Проверяет, можно ли построить модуль в указанной позиции.
## Учитывает: границы сетки, занятость, соседство, питание, ограничения реактора.
## @param pos: Позиция левого верхнего угла модуля.
## @param module_type: Тип модуля (см. Constants.MODULE_*).
## @param size: Размер модуля в ячейках.
## @return: true если постройка разрешена.
func canBuildAt(pos: Vector2i, module_type: String, size: Vector2i = Vector2i.ONE) -> bool:
	if not _is_area_inside_grid(pos, size):
		return false

	if _is_below_core_build_limit(pos, size):
		return false

	if _is_area_occupied(pos, size):
		return false

	# 1. ПРАВИЛО СОСЕДСТВА: Только по горизонтали или вертикали к существующим блокам
	if not _is_cardinally_adjacent_to_occupied(pos, size):
		return false

	# 2. ПРАВИЛО ПИТАНИЯ:
	# Для обычных модулей нужна зона питания, для реактора — нет
	if module_type != Constants.MODULE_REACTOR and not _is_any_cell_powered(pos, size):
		return false

	# 3. ПРАВИЛО ДЛЯ РЕАКТОРА:
	# Его собственная зона питания не должна включать ядро или другие реакторы
	if module_type == Constants.MODULE_REACTOR:
		if _is_area_reactor_restricted(pos, size):
			return false

	return true


## Регистрирует ядро корабля в сетке.
## Ядро является центральным источником питания.
func register_core(pos: Vector2i, size: Vector2i, entity: Node) -> void:
	var core_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in core_cells:
		_occupied_cells[cell] = entity
		if not _core_cells.has(cell): _core_cells.append(cell)
	_rebuild_power_maps()


## Регистрирует модуль в сетке.
## Для реакторов также обновляет зоны питания.
func register_module(pos: Vector2i, size: Vector2i, module_type: String, entity: Node) -> void:
	var module_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in module_cells:
		_occupied_cells[cell] = entity

	if module_type == Constants.MODULE_REACTOR:
		for cell in module_cells:
			if not _reactor_cells.has(cell): _reactor_cells.append(cell)
		_rebuild_power_maps()


## Удаляет модуль из сетки.
func unregister_module(entity: Node) -> void:
	var keys_to_remove: Array[Vector2i] = []
	for key in _occupied_cells.keys():
		if _occupied_cells[key] == entity:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_occupied_cells.erase(key)
		_reactor_cells.erase(key)
		_core_cells.erase(key)
	_rebuild_power_maps()


## Возвращает копию словаря занятых ячеек.
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

func _is_cardinally_adjacent_to_occupied(pos: Vector2i, size: Vector2i) -> bool:
	# Если это самый первый запуск и ничего нет (кроме ядра), 
	# ядро уже зарегистрировано в _occupied_cells, так что этот метод сработает
	var directions = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell = Vector2i(x, y)
			for dir in directions:
				if _occupied_cells.has(cell + dir):
					return true
	return false

func _is_area_reactor_restricted(pos: Vector2i, size: Vector2i) -> bool:
	var radius: int = Constants.CORE_RADIUS_CELLS
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var source_cell: Vector2i = Vector2i(x, y)
			for rx in range(source_cell.x - radius, source_cell.x + radius + 1):
				for ry in range(source_cell.y - radius, source_cell.y + radius + 1):
					var affected_cell: Vector2i = Vector2i(rx, ry)
					if _core_cells.has(affected_cell) or _reactor_cells.has(affected_cell):
						return true
	return false

func _is_below_core_build_limit(pos: Vector2i, size: Vector2i) -> bool:
	if _core_cells.is_empty():
		return false

	var core_bottom_y: int = _core_cells[0].y
	for core_cell in _core_cells:
		if core_cell.y > core_bottom_y:
			core_bottom_y = core_cell.y

	var placement_bottom_y: int = pos.y + size.y - 1
	return placement_bottom_y > core_bottom_y

func _mark_power_around_cells(cells: Array[Vector2i], radius: int) -> void:
	for source_cell in cells:
		for x in range(source_cell.x - radius, source_cell.x + radius + 1):
			for y in range(source_cell.y - radius, source_cell.y + radius + 1):
				var cell = Vector2i(x, y)
				if cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT:
					_powered_cells[cell] = true

func _rebuild_power_maps() -> void:
	_powered_cells.clear()
	if not _core_cells.is_empty():
		_mark_power_around_cells(_core_cells, Constants.CORE_RADIUS_CELLS)
	if not _reactor_cells.is_empty():
		_mark_power_around_cells(_reactor_cells, Constants.CORE_RADIUS_CELLS)

func _collect_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			cells.append(Vector2i(x, y))
	return cells
