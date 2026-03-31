class_name ModuleTacticalPriority
## Статический класс для определения тактического приоритета модулей.
## Используется AI рейдеров для выбора наиболее ценных целей.
## Чем выше приоритет — тем привлекательнее цель для атаки.

const PRIORITY_TURRET: int = 100
const PRIORITY_REACTOR: int = 50
const PRIORITY_COLLECTOR: int = 40
const PRIORITY_HULL: int = 20
const PRIORITY_CORE: int = 10
const PRIORITY_DEFAULT: int = 0


static func get_priority(module_id: String) -> int:
	match module_id:
		Constants.MODULE_TURRET:
			return PRIORITY_TURRET
		Constants.MODULE_REACTOR:
			return PRIORITY_REACTOR
		Constants.MODULE_COLLECTOR:
			return PRIORITY_COLLECTOR
		Constants.MODULE_HULL:
			return PRIORITY_HULL
		Constants.MODULE_CORE:
			return PRIORITY_CORE
		_:
			return PRIORITY_DEFAULT


static func get_priority_name(module_id: String) -> String:
	match module_id:
		Constants.MODULE_TURRET:
			return "Turret (Highest)"
		Constants.MODULE_REACTOR:
			return "Reactor (High)"
		Constants.MODULE_COLLECTOR:
			return "Collector (Medium)"
		Constants.MODULE_HULL:
			return "Hull (Low)"
		Constants.MODULE_CORE:
			return "Core (Lowest)"
		_:
			return "Unknown"
