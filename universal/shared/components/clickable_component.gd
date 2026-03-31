extends Area2D
class_name ClickableComponent
## Универсальный компонент для обработки кликов/тапов.
## Сигналы идут ВВЕРХ по иерархии (Signals Up).

signal clicked

@export var is_enabled: bool = true
@export var one_shot: bool = true

var _already_clicked: bool = false


func _ready() -> void:
	input_pickable = is_enabled


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not is_enabled:
		return

	var is_mouse_click: bool = event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed
	var is_screen_tap: bool = event is InputEventScreenTouch and event.pressed

	if not is_mouse_click and not is_screen_tap:
		return

	if one_shot and _already_clicked:
		return

	_already_clicked = true
	clicked.emit()


func set_enabled(value: bool) -> void:
	is_enabled = value
	input_pickable = value


func reset_click_state() -> void:
	_already_clicked = false
