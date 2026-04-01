extends Area2D
class_name ClickableComponent
## Универсальный компонент для обработки кликов/тапов.
## Используется мусором, модулями и врагами для определения взаимодействия.
## Сигналы идут ВВЕРХ по иерархии (Signals Up).
##
## Пример использования:
## @code
## var clickable = ClickableComponent.new()
## clickable.clicked.connect(_on_clicked)
## add_child(clickable)
## @endcode

## Испускается при клике/тапе по области.
signal clicked

## Включён ли компонент для обработки ввода.
@export var is_enabled: bool = true
## Если true, клик обрабатывается только один раз.
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


## Включает или выключает обработку кликов.
func set_enabled(value: bool) -> void:
	is_enabled = value
	input_pickable = value


## Сбрасывает состояние клика для one_shot режима.
func reset_click_state() -> void:
	_already_clicked = false
