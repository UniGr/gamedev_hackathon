extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var btn_storage: Button = %BtnStorage
@onready var btn_collector: Button = %BtnCollector

func _ready() -> void:
	# Программист 3: Логика UI (HUD, меню, экран победы/поражения)
	GameEvents.resource_changed.connect(_on_resource_changed)
	
	btn_storage.pressed.connect(_on_btn_storage_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int) -> void:
	if type == "metal":
		metal_label.text = "Metal: %d" % new_total

func _on_btn_storage_pressed() -> void:
	GameEvents.build_requested.emit("storage", Vector2.ZERO) # Placeholder pos
	print("Requested Storage")

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit("collector", Vector2.ZERO) # Placeholder pos
	print("Requested Collector")
