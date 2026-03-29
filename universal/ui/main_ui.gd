extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_bar: TextureProgressBar = %MetalBar
@onready var shop_metal_label: Label = %ShopMetalLabel
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_turret: Button = %BtnTurret
@onready var btn_shop: Button = %BtnShop
@onready var btn_shop_exit: Button = %BtnShopExit
@onready var shop_overlay: ColorRect = %ShopOverlay
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title_label: Label = %EndTitleLabel
@onready var end_reason_label: Label = %EndReasonLabel
@onready var btn_restart: Button = %BtnRestart

# Новые элементы Ядра
@onready var core_cost_label: Label = %CoreCost
@onready var core_level_label: Label = %CoreLevelLabel
@onready var core_upgrade_btn: Button = %CoreUpgradeBtn # Мы можем использовать невидимую кнопку или просто клик по плашке
@onready var level_bars_container: HBoxContainer = %LevelBars

var _is_game_finished: bool = false
var _shop_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.module_built.connect(_on_module_built)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)

	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_turret.pressed.connect(_on_btn_turret_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_shop_exit.pressed.connect(_on_btn_shop_exit_pressed)

	# Клик по плашке ядра для апгрейда
	%CorePlaque.gui_input.connect(_on_core_plaque_input)

	_refresh_ui()
	_set_shop_open(false, false)
	end_overlay.visible = false

func _on_resource_changed(type: String, _new_total: int) -> void:
	if type == "metal":
		_refresh_ui()

func _refresh_ui() -> void:
	var metal = ResourceManager.metal
	var max_metal = ResourceManager.max_metal
	metal_label.text = "МЕТАЛЛ %d / %d" % [metal, max_metal]
	shop_metal_label.text = "МЕТАЛЛ %d / %d" % [metal, max_metal]
	
	if metal_bar:
		metal_bar.max_value = max_metal
		metal_bar.value = metal

	# Обновление цен на кнопках модулей
	_update_module_button(btn_hull, Constants.MODULE_HULL, metal)
	_update_module_button(btn_reactor, Constants.MODULE_REACTOR, metal)
	_update_module_button(btn_collector, Constants.MODULE_COLLECTOR, metal)
	_update_module_button(btn_turret, Constants.MODULE_TURRET, metal)

	# Обновление ядра
	_refresh_core_info(metal)

func _update_module_button(btn: Button, type: String, metal: int) -> void:
	var cost = ResourceManager.get_current_module_cost(type)
	var price_label = btn.get_node("V/Price")
	price_label.text = "%d +" % cost
	btn.disabled = metal < cost

	if btn.disabled:
		price_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	else:
		price_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))

func _refresh_core_info(metal: int) -> void:
	var upgrade_id = "core_max_metal" # Предположим, это ID основного апгрейда ядра
	if not UpgradeManager.get_upgrade_ids().has(upgrade_id):
		# Если ID другой, возьмем первый попавшийся или пропустим
		if UpgradeManager.get_upgrade_ids().size() > 0:
			upgrade_id = UpgradeManager.get_upgrade_ids()[0]

	var level = UpgradeManager.get_upgrade_level(upgrade_id)
	var max_lvl = UpgradeManager.get_upgrade_max_level(upgrade_id)
	var cost = UpgradeManager.get_upgrade_next_cost(upgrade_id)

	core_level_label.text = "УРОВЕНЬ %d / %d" % [level, max_lvl]

	if level >= max_lvl:
		core_cost_label.text = "MAX"
	else:
		core_cost_label.text = "%d •" % cost
		if metal < cost:
			core_cost_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		else:
			core_cost_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))

	# Обновление сегментов уровня
	var bars = level_bars_container.get_children()
	for i in range(bars.size()):
		if i < level:
			bars[i].add_theme_stylebox_override("panel", load("res://ui/main_ui.tscn::StyleBoxFlat_LevelSlotFull"))
		else:
			bars[i].add_theme_stylebox_override("panel", load("res://ui/main_ui.tscn::StyleBoxFlat_LevelSlot"))

func _on_core_plaque_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var upgrade_id = "core_max_metal"
		if UpgradeManager.get_upgrade_ids().size() > 0:
			if not UpgradeManager.get_upgrade_ids().has(upgrade_id):
				upgrade_id = UpgradeManager.get_upgrade_ids()[0]
			if UpgradeManager.purchase(upgrade_id):
				AudioManager.play_ui_click()
				_refresh_ui()

func _on_btn_shop_pressed() -> void:
	if _is_game_finished: return
	AudioManager.play_ui_open()
	_set_shop_open(not _shop_open, true)

func _set_shop_open(value: bool, sync_pause: bool) -> void:
	_shop_open = value
	shop_overlay.visible = value
	if sync_pause:
		get_tree().paused = value

func _on_btn_shop_exit_pressed() -> void:
	AudioManager.play_ui_click()
	_set_shop_open(false, true)

func _on_module_built(_type: String, _pos: Vector2) -> void:
	_set_shop_open(false, true)
	_refresh_ui()

func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_refresh_ui()

func _on_btn_hull_pressed() -> void: _request_build(Constants.MODULE_HULL)
func _on_btn_reactor_pressed() -> void: _request_build(Constants.MODULE_REACTOR)
func _on_btn_collector_pressed() -> void: _request_build(Constants.MODULE_COLLECTOR)
func _on_btn_turret_pressed() -> void: _request_build(Constants.MODULE_TURRET)

func _request_build(type: String) -> void:
	if _is_game_finished: return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(type, Vector2.ZERO)
	_set_shop_open(false, false) # Закрываем для выбора места

func _on_game_finished(outcome: String, reason: String) -> void:
	_is_game_finished = true
	_set_shop_open(false, false)
	get_tree().paused = true
	end_overlay.visible = true
	if outcome == "win":
		end_title_label.text = "ПОБЕДА"
		end_reason_label.text = "Миссия выполнена!"
	else:
		end_title_label.text = "GAME OVER"
		end_reason_label.text = "Ядро уничтожено."

func _on_btn_restart_pressed() -> void:
	get_tree().paused = false
	if ResourceManager.has_method("reset"): ResourceManager.reset()
	if UpgradeManager.has_method("reset"): UpgradeManager.reset()
	get_tree().reload_current_scene()
