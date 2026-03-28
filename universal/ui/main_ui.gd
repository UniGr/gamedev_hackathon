extends CanvasLayer

func _ready() -> void:
	# Программист 3: Логика UI (HUD, меню, экран победы/поражения)
	GameEvents.resource_changed.connect(_on_resource_changed)
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int) -> void:
	if type == "metal":
		# Обновление счетчика металла в UI
		pass
