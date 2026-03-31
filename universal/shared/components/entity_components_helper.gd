extends RefCounted
class_name EntityComponentsHelper
## Утилита для инициализации общих компонентов сущностей.
## Используется для Raider, ModuleBase и других сущностей с HP + Clickable.

const HEALTH_COMPONENT_SCRIPT: Script = preload("res://shared/components/health_component.gd")


## Создает или получает существующий HealthComponent.
## Возвращает HealthComponent или null при ошибке.
static func ensure_health_component(
	parent: Node,
	max_hp: int,
	initial_hp: int = -1
) -> HealthComponent:
	var existing: Node = parent.get_node_or_null("HealthComponent")
	if existing is HealthComponent:
		var health: HealthComponent = existing as HealthComponent
		health.max_hp = max(1, max_hp)
		if initial_hp > 0:
			health.initial_hp = initial_hp
		return health
	
	var health: HealthComponent = HEALTH_COMPONENT_SCRIPT.new() as HealthComponent
	health.name = "HealthComponent"
	health.max_hp = max(1, max_hp)
	health.initial_hp = initial_hp if initial_hp > 0 else health.max_hp
	parent.add_child(health)
	return health


## Настраивает HealthComponent с полным набором коллбеков.
## Подключает сигналы damaged, died, hp_changed к указанным Callable.
static func setup_health_signals(
	health: HealthComponent,
	on_damaged: Callable = Callable(),
	on_died: Callable = Callable(),
	on_hp_changed: Callable = Callable()
) -> void:
	if health == null:
		return
	
	if on_damaged.is_valid() and not health.damaged.is_connected(on_damaged):
		health.damaged.connect(on_damaged)
	
	if on_died.is_valid() and not health.died.is_connected(on_died):
		health.died.connect(on_died)
	
	if on_hp_changed.is_valid() and not health.hp_changed.is_connected(on_hp_changed):
		health.hp_changed.connect(on_hp_changed)
