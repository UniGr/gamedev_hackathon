extends Node
class_name TargetPressureTracker
## Отслеживает "давление" на модули со стороны рейдеров.
## Позволяет AI рейдеров выбирать менее атакуемые цели для распределения урона.
## Принцип: Signals Up, Calls Down — этот компонент не знает о родителе.

var _pressure_by_target: Dictionary = {}


func claim_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	_pressure_by_target[target] = int(_pressure_by_target.get(target, 0)) + 1


func release_target(target: Node) -> void:
	if target == null:
		return
	if not _pressure_by_target.has(target):
		return
	var next_value: int = int(_pressure_by_target[target]) - 1
	if next_value <= 0:
		_pressure_by_target.erase(target)
	else:
		_pressure_by_target[target] = next_value


func get_pressure(target: Node) -> int:
	if target == null:
		return 0
	return int(_pressure_by_target.get(target, 0))


func clear_target(target: Node) -> void:
	if target == null:
		return
	_pressure_by_target.erase(target)


func reset() -> void:
	_pressure_by_target.clear()
