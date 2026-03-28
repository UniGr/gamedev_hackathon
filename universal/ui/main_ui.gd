extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_bar: ProgressBar = %MetalBar
@onready var energy_label: Label = %EnergyLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var btn_storage: Button = %BtnStorage
@onready var btn_collector: Button = %BtnCollector
@onready var btn_shop: Button = %BtnShop
@onready var bottom_panel: HBoxContainer = %BottomPanel

# Цены модулей (в будущем будут грузиться из .tres)
const COST_STORAGE = 5
const COST_COLLECTOR = 10

func _ready() -> void:
	# Программист 3: Логика UI (HUD, меню, экран победы/поражения)
	GameEvents.resource_changed.connect(_on_resource_changed)
	
	btn_storage.pressed.connect(_on_btn_storage_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	
	# По умолчанию магазин закрыт (или открыт, как удобнее)
	bottom_panel.visible = false
	
	# Начальная проверка кнопок
	_update_buttons(0)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int, max_total: int) -> void:
	if type == "metal":
		metal_label.text = "Металл: %d / %d" % [new_total, max_total]
		metal_bar.max_value = max_total
		metal_bar.value = new_total
		_update_buttons(new_total)
		_flash_label(metal_label)
	elif type == "energy":
		energy_label.text = "⚡ %d / %d" % [new_total, max_total]
		energy_bar.max_value = max_total
		energy_bar.value = new_total
		_flash_label(energy_label)

func _flash_label(label: Label) -> void:
	var tween = create_tween()
	label.modulate = Color(0.5, 1.5, 0.5) # Вспышка
	tween.tween_property(label, "modulate", Color.WHITE, 0.3)

func _update_buttons(current_metal: int) -> void:
	btn_storage.disabled = current_metal < COST_STORAGE
	btn_collector.disabled = current_metal < COST_COLLECTOR

func _on_btn_shop_pressed() -> void:
	bottom_panel.visible = !bottom_panel.visible
	print("Shop toggled: ", bottom_panel.visible)

# Временный тест: клик в любом месте добавляет металл и энергию
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		GameEvents.garbage_clicked.emit(1)
		# Тестово добавим энергию тоже
		_test_add_energy(2)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameEvents.garbage_clicked.emit(1)
		_test_add_energy(2)

func _test_add_energy(amount: int) -> void:
	#ResourceManager должен это делать, но для теста UI:
	var rm = get_tree().root.find_child("ResourceManager", true, false)
	if rm:
		rm.add_energy(amount)

func _on_btn_storage_pressed() -> void:
	GameEvents.build_requested.emit("storage", Vector2.ZERO) # Placeholder pos
	print("Requested Storage")

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit("collector", Vector2.ZERO) # Placeholder pos
	print("Requested Collector")
