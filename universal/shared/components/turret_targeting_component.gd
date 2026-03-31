extends Node
class_name TurretTargetingComponent
## Компонент поиска целей для турели.
## Поддерживает режимы: NEAREST, LOWEST_HP, ADAPTIVE.

signal target_acquired(target: Node2D)
signal target_lost()

enum TargetMode {
	NEAREST,
	LOWEST_HP,
	ADAPTIVE,
}

@export var target_mode: TargetMode = TargetMode.ADAPTIVE
@export var attack_range_cells: float = 4.8
@export var lock_on_after_shots: int = 3

var _current_target: Node2D
var _consecutive_hits_on_target: int = 0
var _cell_size_px: float = 90.0
var _raider_group: String = "raiders"


func configure(cell_size_px: float, range_cells: float, mode: TargetMode) -> void:
	_cell_size_px = maxf(1.0, cell_size_px)
	attack_range_cells = maxf(0.5, range_cells)
	target_mode = mode


func set_cell_size(cell_size_px: float) -> void:
	_cell_size_px = maxf(1.0, cell_size_px)


func get_current_target() -> Node2D:
	return _current_target


func is_target_valid() -> bool:
	return _current_target != null and is_instance_valid(_current_target)


func find_target(from_center: Vector2) -> Node2D:
	var raiders: Array = get_tree().get_nodes_in_group(_raider_group)
	if raiders.is_empty():
		_reset_lock_on()
		return null

	var range_px: float = attack_range_cells * _cell_size_px
	var best_target: Node2D = null
	var best_score: float = INF

	for node in raiders:
		if not (node is Node2D):
			continue
		var raider: Node2D = node as Node2D
		if not is_instance_valid(raider):
			continue

		var distance: float = from_center.distance_to(raider.global_position)
		if distance > range_px:
			continue

		var score: float = _calculate_score(raider, distance)
		if score < best_score:
			best_score = score
			best_target = raider

	if best_target != _current_target:
		_reset_lock_on()
		_current_target = best_target
		if _current_target != null:
			target_acquired.emit(_current_target)
		else:
			target_lost.emit()

	return best_target


func register_hit(target: Node2D) -> void:
	if target == _current_target:
		_consecutive_hits_on_target += 1
	else:
		_current_target = target
		_consecutive_hits_on_target = 1


func is_locked_on() -> bool:
	return _consecutive_hits_on_target >= maxi(1, lock_on_after_shots)


func get_consecutive_hits() -> int:
	return _consecutive_hits_on_target


func clear_target() -> void:
	_current_target = null
	_reset_lock_on()
	target_lost.emit()


func _reset_lock_on() -> void:
	_consecutive_hits_on_target = 0


func _calculate_score(raider: Node2D, distance: float) -> float:
	var score: float = distance

	match target_mode:
		TargetMode.NEAREST:
			return distance

		TargetMode.LOWEST_HP:
			if raider.has_method("get_hp_ratio"):
				var hp_ratio: float = float(raider.call("get_hp_ratio"))
				score = hp_ratio * 1000.0 + distance
			return score

		TargetMode.ADAPTIVE:
			var hp_factor: float = 0.0
			if raider.has_method("get_hp_ratio"):
				hp_factor = float(raider.call("get_hp_ratio")) * 520.0

			var lock_bonus: float = 0.0
			if raider == _current_target:
				lock_bonus = -220.0

			return distance + hp_factor + lock_bonus

		_:
			return distance
