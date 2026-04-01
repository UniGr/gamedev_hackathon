extends Node
## Менеджер ресурсов: управляет Металлом
## Все константы баланса загружаются из Constants.gd (которые загружают .tres конфиги)

var metal: int = 0
var max_metal: int = 0
var _max_metal_reached_notified: bool = false
var build_iterations_by_module: Dictionary = {
	Constants.MODULE_REACTOR: 0,
	Constants.MODULE_HULL: 0,
	Constants.MODULE_COLLECTOR: 0,
	Constants.MODULE_TURRET: 0,
}

func _ready() -> void:
	# Инициализируем начальные значения из Constants
	metal = Constants.get_resource_initial_metal()
	max_metal = Constants.get_resource_max_metal()
	
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	# Мы слушаем ПОСТРОЕННЫЕ модули, чтобы обновлять лимиты
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.module_destroyed.connect(_on_module_destroyed)
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	GameEvents.resource_changed.emit("metal", metal)


func reset_run_state() -> void:
	metal = Constants.get_resource_initial_metal()
	max_metal = Constants.get_resource_max_metal()
	_max_metal_reached_notified = false
	for module_id in build_iterations_by_module.keys():
		build_iterations_by_module[module_id] = 0
	GameEvents.resource_changed.emit("metal", metal)

func add_metal(amount: int) -> void:
	metal = min(metal + amount, max_metal)
	# Проверяем, достигли ли максимум в первый раз
	if metal == max_metal and not _max_metal_reached_notified:
		_max_metal_reached_notified = true
		GameEvents.max_resources_reached.emit("metal", metal)
	GameEvents.resource_changed.emit("metal", metal)

func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		GameEvents.resource_changed.emit("metal", metal)
		return true
	return false


func get_current_module_cost(module_id: String) -> int:
	return Constants.get_module_cost_for_iteration(module_id, get_module_build_iteration(module_id))


func get_module_build_iteration(module_id: String) -> int:
	return int(build_iterations_by_module.get(module_id, 0))


func set_module_build_iterations(raw_iterations: Dictionary) -> void:
	for module_id in build_iterations_by_module.keys():
		var value: int = int(raw_iterations.get(module_id, 0))
		build_iterations_by_module[module_id] = max(0, value)

func _on_garbage_clicked(amount: int) -> void:
	add_metal(amount)

func _on_module_built(module_type: String, _pos: Vector2) -> void:
	if Constants.is_incremental_price_module(module_type):
		build_iterations_by_module[module_type] = get_module_build_iteration(module_type) + 1

	if module_type == Constants.MODULE_HULL:
		# Модуль корпуса увеличивает лимит металла
		max_metal += Constants.get_hull_metal_bonus()
		_max_metal_reached_notified = false
		GameEvents.resource_changed.emit("metal", metal)


func _on_module_destroyed(module_type: String, _pos: Vector2) -> void:
	if module_type != Constants.MODULE_HULL:
		return

	# При разрушении корпуса возвращаем лимит металла
	max_metal = max(Constants.get_resource_max_metal(), max_metal - Constants.get_hull_metal_bonus())
	metal = min(metal, max_metal)
	GameEvents.resource_changed.emit("metal", metal)
