extends Node
class_name HeatManagementComponent
## Компонент управления перегревом для турелей.
## Отслеживает накопление тепла и автоматическое охлаждение.

signal overheated()
signal cooled_down()
signal heat_changed(current_heat: float, max_heat: float)

@export var heat_per_shot: float = 0.16
@export var cool_per_sec: float = 0.42
@export var overheat_threshold: float = 1.0
@export var cooldown_resume_threshold: float = 0.35

var _heat: float = 0.0
var _is_overheated: bool = false


func _process(delta: float) -> void:
	if _heat <= 0.0:
		return

	var old_heat: float = _heat
	_heat = maxf(0.0, _heat - cool_per_sec * delta)

	if _is_overheated and _heat <= cooldown_resume_threshold:
		_is_overheated = false
		cooled_down.emit()

	if old_heat != _heat:
		heat_changed.emit(_heat, overheat_threshold)


func configure(per_shot: float, per_sec: float, threshold: float, resume: float) -> void:
	heat_per_shot = maxf(0.01, per_shot)
	cool_per_sec = maxf(0.01, per_sec)
	overheat_threshold = maxf(0.1, threshold)
	cooldown_resume_threshold = clampf(resume, 0.0, overheat_threshold * 0.9)


func add_heat(amount: float = -1.0) -> void:
	if amount < 0.0:
		amount = heat_per_shot
	_heat += maxf(0.0, amount)
	heat_changed.emit(_heat, overheat_threshold)

	if not _is_overheated and _heat >= overheat_threshold:
		_is_overheated = true
		overheated.emit()


func is_overheated() -> bool:
	return _is_overheated


func get_heat() -> float:
	return _heat


func get_heat_ratio() -> float:
	if overheat_threshold <= 0.0:
		return 0.0
	return clampf(_heat / overheat_threshold, 0.0, 1.0)


func reset() -> void:
	_heat = 0.0
	_is_overheated = false
	heat_changed.emit(_heat, overheat_threshold)


func force_overheat() -> void:
	_heat = overheat_threshold
	_is_overheated = true
	overheated.emit()
	heat_changed.emit(_heat, overheat_threshold)
