extends RefCounted
class_name BuildModeTopPanelController
## Контроллер верхней панели в режиме строительства.
## Подменяет стандартную панель ресурсов на панель характеристик модуля.

const MODULE_STATS: Dictionary = {
	"collector": {"label": "Металл/сек"},
	"turret":    {"label": "Урон/сек"},
	"hull":      {"label": "Макс. металл"},
	"reactor":   {"label": "Зоны реактора"},
}

var _build_mode_panel: PanelContainer
var _build_mode_label: Label
var _build_mode_value: Label
var _is_active: bool = false


func setup(build_panel: PanelContainer, build_label: Label, build_value: Label) -> void:
	_build_mode_panel = build_panel
	_build_mode_label = build_label
	_build_mode_value = build_value
	_build_mode_panel.visible = false


func enter_build_mode(module_type: String) -> void:
	_is_active = true
	var stats: Dictionary = MODULE_STATS.get(module_type, {"label": module_type})

	if _build_mode_label:
		_build_mode_label.text = stats["label"]

	if _build_mode_value:
		_build_mode_value.text = _get_stat_text(module_type)

	if _build_mode_panel:
		_build_mode_panel.visible = true


func exit_build_mode() -> void:
	_is_active = false
	if _build_mode_panel:
		_build_mode_panel.visible = false


func is_active() -> bool:
	return _is_active


func _get_stat_text(module_type: String) -> String:
	match module_type:
		"collector":
			var config: CollectorConfig = load("res://data/collector_config.tres") as CollectorConfig
			if config:
				var delta: float = 1.0 / config.collect_cooldown_sec
				var count: int = ResourceManager.active_module_counts.get(Constants.MODULE_COLLECTOR, 0)
				var current: float = count * delta
				return "%.1f  →  +%.1f" % [current, delta]
			return "+?"
		"turret":
			var config: TurretConfig = load("res://data/turret_config.tres") as TurretConfig
			if config:
				var dps: float = float(config.turret_damage) / config.fire_cooldown_sec
				var count: int = ResourceManager.active_module_counts.get(Constants.MODULE_TURRET, 0)
				var current: float = count * dps
				return "%.0f  →  +%.0f" % [current, dps]
			return "+?"
		"hull":
			var bonus: int = Constants.get_hull_metal_bonus()
			var current: int = ResourceManager.max_metal
			return "%d  →  +%d" % [current, bonus]
		"reactor":
			var count: int = ResourceManager.active_module_counts.get(Constants.MODULE_REACTOR, 0)
			return "%d  →  +1" % count
		_:
			return "+"
