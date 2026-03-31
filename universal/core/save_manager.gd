extends Node
class_name SaveManagerClass
## Автозагрузка: SaveManager
## Управление сохранением и загрузкой игрового прогресса.

const SAVE_TIME_SECONDS: float = 60.0
const SAVE_PATH: String = "user://universal_save.json"

var tutorial_flags: Dictionary = {}
var _autosave_timer: Timer


func _ready() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = SAVE_TIME_SECONDS
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(save_game)
	add_child(_autosave_timer)
	
	# Загружаем флаги туториалов при старте
	load_game()


func save_game() -> void:
	var grid_manager: Node = get_tree().root.find_child("GridManager", true, false)
	var grid_data: Dictionary = {}
	if grid_manager != null and grid_manager.has_method("get_occupied_cells"):
		grid_data = _serialize_grid(grid_manager.get_occupied_cells())

	var save_dict: Dictionary = {
		"resources": _get_resources_snapshot(),
		"tutorial": tutorial_flags.duplicate(true),
		"grid": grid_data
	}
	
	var json_string: String = JSON.stringify(save_dict)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		print("SaveManager: Game saved successfully!")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	
	var json_string: String = file.get_as_text()
	var save_dict: Variant = JSON.parse_string(json_string)
	
	if save_dict == null or not (save_dict is Dictionary):
		return
	
	var data: Dictionary = save_dict as Dictionary
	
	# Загружаем туториалы
	var loaded_tutorial_flags: Dictionary = data.get("tutorial", {})
	tutorial_flags = loaded_tutorial_flags.duplicate(true)
	
	# Применяем данные ресурсов
	_apply_resources_data(data.get("resources", {}))
	
	GameEvents.resource_changed.emit("metal", ResourceManager.metal)
	print("SaveManager: Game loaded!")


func _get_resources_snapshot() -> Dictionary:
	return {
		"metal": ResourceManager.metal,
		"max_metal": ResourceManager.max_metal,
		"build_iterations_by_module": ResourceManager.build_iterations_by_module.duplicate(true),
		"upgrade_levels": UpgradeManager.get_upgrade_levels_snapshot()
	}


func _apply_resources_data(res_data: Dictionary) -> void:
	ResourceManager.metal = int(res_data.get("metal", 0))
	ResourceManager.max_metal = int(res_data.get("max_metal", 50))
	
	var loaded_iterations: Dictionary = res_data.get("build_iterations_by_module", {})
	# Legacy migration
	if loaded_iterations.is_empty() and res_data.has("build_iteration"):
		var legacy_iteration: int = int(res_data.get("build_iteration", 0))
		loaded_iterations = {
			Constants.MODULE_REACTOR: legacy_iteration,
			Constants.MODULE_HULL: legacy_iteration,
			Constants.MODULE_COLLECTOR: legacy_iteration,
			Constants.MODULE_TURRET: legacy_iteration,
		}
	ResourceManager.set_module_build_iterations(loaded_iterations)
	
	var loaded_upgrade_levels: Dictionary = res_data.get("upgrade_levels", {})
	UpgradeManager.set_upgrade_levels(loaded_upgrade_levels)


func is_tutorial_shown(tutorial_id: String) -> bool:
	return bool(tutorial_flags.get(tutorial_id, false))


func mark_tutorial_shown(tutorial_id: String) -> void:
	if bool(tutorial_flags.get(tutorial_id, false)):
		return
	tutorial_flags[tutorial_id] = true
	save_game()


func _serialize_grid(grid: Dictionary) -> Dictionary:
	var string_grid: Dictionary = {}
	for pos: Vector2i in grid:
		var pos_str: String = "%d,%d" % [pos.x, pos.y]
		var entity: Variant = grid[pos]
		if entity != null and entity is Object and "module_id" in entity:
			string_grid[pos_str] = entity.module_id
		else:
			string_grid[pos_str] = "unknown"
	return string_grid


func _deserialize_grid(string_grid: Dictionary) -> Dictionary:
	var grid: Dictionary = {}
	for pos_str: String in string_grid:
		var parts: PackedStringArray = pos_str.split(",")
		if parts.size() == 2:
			var pos: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
			grid[pos] = string_grid[pos_str]
	return grid
