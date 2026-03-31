extends RefCounted
class_name ClickableSetup
## Утилита для инициализации кликабельных компонентов.
## Убирает дублирование кода из Raider.gd и ModuleBase.gd.

const CLICKABLE_SCRIPT: Script = preload("res://shared/components/clickable_component.gd")


## Создает Area2D с ClickableComponent и CollisionShape2D.
## Возвращает словарь с ключами: "clickable" (Area2D), "collision" (CollisionShape2D)
static func create_clickable(
	parent: Node,
	on_clicked: Callable,
	one_shot: bool = false
) -> Dictionary:
	var clickable: Area2D = Area2D.new()
	clickable.name = "ClickableComponent"
	clickable.script = CLICKABLE_SCRIPT
	clickable.set("one_shot", one_shot)
	parent.add_child(clickable)
	
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	clickable.add_child(collision)
	
	if clickable.has_signal("clicked") and on_clicked.is_valid():
		clickable.connect("clicked", on_clicked)
	
	return {
		"clickable": clickable,
		"collision": collision,
	}


## Обновляет размер RectangleShape2D для прямоугольного хитбокса.
static func update_rect_shape(
	collision: CollisionShape2D,
	size: Vector2
) -> void:
	if collision == null or not is_instance_valid(collision):
		return
	
	var rect_shape: RectangleShape2D
	if collision.shape is RectangleShape2D:
		rect_shape = collision.shape as RectangleShape2D
	else:
		rect_shape = RectangleShape2D.new()
		collision.shape = rect_shape
	
	rect_shape.size = size
	collision.position = size * 0.5


## Обновляет радиус CircleShape2D для круглого хитбокса.
static func update_circle_shape(
	collision: CollisionShape2D,
	radius: float
) -> void:
	if collision == null or not is_instance_valid(collision):
		return
	
	var circle: CircleShape2D
	if collision.shape is CircleShape2D:
		circle = collision.shape as CircleShape2D
	else:
		circle = CircleShape2D.new()
		collision.shape = circle
	
	circle.radius = radius
