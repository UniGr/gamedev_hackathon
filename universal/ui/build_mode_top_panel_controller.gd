extends RefCounted
class_name BuildModeTopPanelController
## Контроллер верхней панели в режиме строительства.
## Подменяет стандартную панель ресурсов на панель характеристик модуля.

const MODULE_STATS: Dictionary = {
	"collector": {"label": "Металл/сек", "format": "+%s"},
	"turret": {"label": "Урон/сек", "format": "+%s"},
	"hull": {"label": "Макс. металл", "format": "+%d"},
	"reactor": {"label": "Энергия", "format": "+зона"},
}

var _build_mode_panel: PanelContainer
var _build_mode_label: Label
var _build_mode_value: Label
var _normal_top_panel: Control
var _is_active: bool = false


func setup(build_panel: PanelContainer, build_label: Label, build_value: Label, normal_panel: Control) -> void:
	_build_mode_panel = build_panel
	_build_mode_label = build_label
	_build_mode_value = build_value
	_normal_top_panel = normal_panel
	_build_mode_panel.visible = false


func enter_build_mode(module_type: String) -> void:
	_is_active = true
	var stats: Dictionary = MODULE_STATS.get(module_type, {"label": module_type, "format": "+"})

	if _build_mode_label:
		_build_mode_label.text = stats["label"]

	if _build_mode_value:
		var value_text: String = _get_stat_value(module_type, stats["format"])
		_build_mode_value.text = value_text

	if _normal_top_panel:
		_normal_top_panel.visible = false
	if _build_mode_panel:
		_build_mode_panel.visible = true


func exit_build_mode() -> void:
	_is_active = false
	if _build_mode_panel:
		_build_mode_panel.visible = false
	if _normal_top_panel:
		_normal_top_panel.visible = true


func is_active() -> bool:
	return _is_active


func _get_stat_value(module_type: String, fmt: String) -> String:
	match module_type:
		"collector":
			var config: CollectorConfig = load("res://data/collector_config.tres") as CollectorConfig
			if config:
				var rate: String = "%.1f" % (1.0 / config.collect_cooldown_sec)
				return fmt % rate
			return fmt % "?"
		"turret":
			var config: TurretConfig = load("res://data/turret_config.tres") as TurretConfig
			if config:
				var dps: String = "%.0f" % (float(config.turret_damage) / config.fire_cooldown_sec)
				return fmt % dps
			return fmt % "?"
		"hull":
			var bonus: int = Constants.get_hull_metal_bonus()
			return fmt % bonus
		"reactor":
			return fmt
		_:
			return "+"
