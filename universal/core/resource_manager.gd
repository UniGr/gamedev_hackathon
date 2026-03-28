extends Node
## Менеджер ресурсов: выслеживает и управляет Металлом и Энергией

var metal: int = 0
var energy: int = 0

# Максимум ресурсов
var max_metal: int = 100
var max_energy: int = 500


func _ready() -> void:
	# При запуске подписываемся на события
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	# Отправляем начальные значения UI
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	GameEvents.resource_changed.emit("metal", metal, max_metal)
	GameEvents.resource_changed.emit("energy", energy, max_energy)

## Добавить металл
func add_metal(amount: int) -> void:
	metal = min(metal + amount, max_metal)
	GameEvents.resource_changed.emit("metal", metal, max_metal)


## Потратить металл
func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		GameEvents.resource_changed.emit("metal", metal, max_metal)
		return true
	return false


## Добавить энергию
func add_energy(amount: int) -> void:
	energy = min(energy + amount, max_energy)
	GameEvents.resource_changed.emit("energy", energy, max_energy)


## Потратить энергию
func spend_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		GameEvents.resource_changed.emit("energy", energy, max_energy)
		return true
	return false


func _on_garbage_clicked(amount: int) -> void:
	add_metal(amount)
