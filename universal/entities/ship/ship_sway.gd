extends Node
class_name ShipSway

@export var sway_amplitude_px: float = 16.0
@export var sway_frequency_hz: float = 0.22
@export var settle_speed: float = 7.0
@export var target_a_path: NodePath = NodePath("../ModulesRoot")
@export var target_b_path: NodePath = NodePath("../HighlightsRoot")
## Если задан и найден — sway не пишет позицию сам, а отдаёт смещение масштабатору,
## который является единственным владельцем трансформа.
@export var auto_scaler_path: NodePath = NodePath("../ShipAutoScaler")

var _elapsed: float = 0.0
var _base_a: Vector2 = Vector2.ZERO
var _base_b: Vector2 = Vector2.ZERO
var _target_a: Node2D
var _target_b: Node2D
var _scaler: Node


func _ready() -> void:
	# Это чисто визуальный эффект, поэтому он должен останавливаться на паузе.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_try_bind_targets()


func _process(delta: float) -> void:
	_elapsed += delta
	var sway_x: float = sin(_elapsed * TAU * sway_frequency_hz) * sway_amplitude_px
	var offset := Vector2(sway_x, 0.0)

	# Предпочтительный путь: отдаём смещение масштабатору (он владеет трансформом).
	if _scaler == null or not is_instance_valid(_scaler):
		_scaler = get_node_or_null(auto_scaler_path)
	if _scaler != null and is_instance_valid(_scaler) and _scaler.has_method("set_sway_offset"):
		_scaler.call("set_sway_offset", offset)
		return

	# Legacy fallback: масштабатора нет — двигаем узлы сами.
	if _target_a == null or _target_b == null:
		_try_bind_targets()
		return

	_target_a.position = _target_a.position.lerp(_base_a + offset, min(1.0, settle_speed * delta))
	_target_b.position = _target_b.position.lerp(_base_b + offset, min(1.0, settle_speed * delta))


func _try_bind_targets() -> void:
	_target_a = get_node_or_null(target_a_path) as Node2D
	_target_b = get_node_or_null(target_b_path) as Node2D
	if _target_a != null and _target_b != null:
		_base_a = _target_a.position
		_base_b = _target_b.position
