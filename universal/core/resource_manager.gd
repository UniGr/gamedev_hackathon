extends Node
## Менеджер ресурсов: управляет Металлом

var metal: int = 0
var max_metal: int = 50

func _ready() -> void:
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	# Мы слушаем ПОСТРОЕННЫЕ модули, чтобы обновлять лимиты
	GameEvents.module_built.connect(_on_module_built)
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	GameEvents.resource_changed.emit("metal", metal, max_metal)

func add_metal(amount: int) -> void:
	metal = min(metal + amount, max_metal)
	GameEvents.resource_changed.emit("metal", metal, max_metal)

func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		GameEvents.resource_changed.emit("metal", metal, max_metal)
		return true
	return false

func _on_garbage_clicked(amount: int) -> void:
	add_metal(amount)

func _on_module_built(type: String, _pos: Vector2) -> void:
	if type == Constants.MODULE_REACTOR:
		# Реактор увеличивает лимит металла (например, на 50)
		max_metal += 50
		GameEvents.resource_changed.emit("metal", metal, max_metal)
		print("Resource Manager: Reactor built! New max metal: ", max_metal)
