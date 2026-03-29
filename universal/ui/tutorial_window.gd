extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

const COLOR_HULL_TEXT: String = "#4DCC4D"
const COLOR_REACTOR_TEXT: String = "#F2BD33"
const COLOR_COLLECTOR_TEXT: String = "#FFE633"
const COLOR_TURRET_TEXT: String = "#F2522E"
const COLOR_CORE_TEXT: String = "#F0D020"

# ========== ТЕКСТЫ ДИАЛОГОВ ==========
var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это [color=yellow]Н.А.Д.Я.[/color], ваша Наблюдательная Автономная Диспетчерская Ячейка.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
]

var gathering_steps: Array[String] = [
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему [color=brown]МУСОРУ[/color], чтобы добыть [color=orange]МЕТАЛЛ[/color]!",
]

var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это [color=red]ВРАГ[/color]. Он хочет забрать наши ресурсы.",
    "Чтобы уничтожить врага, нажимайте по нему так быстро как только сможете"
]

var raider_defense_steps: Array[String] = [
	"Отличная работа, Капитан!",
    "Напоминаю, для автоматизации защиты от [color=red]ВРАГОВ[/color] постройте ТУРЕЛИ: их можно купить в магазине."
]

var shop_invite_steps: Array[String] = [
    "Капитан, у вас достаточно [color=orange]МЕТАЛЛА[/color]! Зайдите в [color=green]МАГАЗИН[/color], чтобы купить модули для корабля."
]

var shop_guide_steps: Array[String] = [
	"Магазин открыт! Я расскажу об основных модулях, каждый  из них уникален и необходим нашему кораблю:",
	"[color=%s]КОРПУС[/color] — увеличивает максимальное количество ресурсов." % COLOR_HULL_TEXT,
	"[color=%s]РЕАКТОР[/color] — без них у нас не будет энергии для работы модулей." % COLOR_REACTOR_TEXT,
	"Реактор запитывает соседние ячейки и позволяет строить модули в них",
	"Обратите внимание, что [color=%s]РЕАКТОРЫ[/color] не должны питать [color=%s]ЯДРО[/color] и наоборот" % [COLOR_REACTOR_TEXT, COLOR_CORE_TEXT],
	"[color=%s]СБОРЩИК[/color] — автоматически добывает ближайший к к вашему кораблю мусор" % COLOR_COLLECTOR_TEXT,
	"[color=%s]ТУРЕЛЬ[/color] — оборонительный модуль, атакует врагов автоматически." % COLOR_TURRET_TEXT,
	"[color=%s]ЯДРО[/color] — увеличивает количество металла, получаемого с каждого обломка." % COLOR_CORE_TEXT,
	"Сейчас у нас хватает [color=orange]МЕТАЛЛА[/color] на [color=%s]КОРПУС[/color]. Самое время его приобрести" % COLOR_HULL_TEXT,
	"Не переживайте, я буду указывать на разрешенные места для строительства модулей",
]
var reactor_guide_steps: Array[String] = [
	"Капитан, вы накопили [color=orange]375 МЕТАЛЛА[/color]! Этого хватит для постройки [color=cyan]РЕАКТОРА[/color].",
	"Каждому новому отсеку нужна энергия. Постройте [color=cyan]РЕАКТОР[/color], чтобы увеличить энергоемкость корабля и продолжить расширение базы!",
    "Если вам удастся построить [color=cyan]4 РЕАКТОРА[/color],нам хватит энергии для [color=cyan]ГИПЕРПРЫЖКA[/color]"
]

var max_resources_steps: Array[String] = [
	"Капитан! Мы накопили максимальное количество [color=orange]МЕТАЛЛА[/color]!",
	"Нам нужно потратить ресурсы на постройку модулей или апгрейдов. Направляйтесь в [color=cyan]МАГАЗИН[/color] и используйте металл!",
]

# ========== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ==========
var dialog_queue: Array[Array] = [] # Очередь диалогов
var tutorial_steps: Array[String] = []
var current_step: int = 0
var is_typing: bool = false
var typing_tween: Tween
var highlight_tween: Tween

# Флаги состояний и паузы
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _raider_defense_shown: bool = false
var _shop_invite_shown: bool = false
var _shop_guide_shown: bool = false
var _reactor_guide_shown: bool = false
# var _max_resources_shown: bool = false
var _max_resources_shown_times: int = 0


# Флаг для защиты от закликивания (анти-скип)
var _is_input_blocked: bool = false
var _focused_target_id: String = ""
var _focused_target_rect: Rect2 = Rect2()
var _step_allows_target_interaction: bool = false
var _step_action_id: String = ""
var _focus_cutout_panels: Array[ColorRect] = []
var _cutout_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Работаем даже при паузе
	hide()
	dialog_text.bbcode_enabled = true
	
	_create_cutout_layer()
	
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.max_resources_reached.connect(_on_max_resources_reached)
	GameEvents.shop_opened.connect(_on_shop_opened)
	GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.tutorial_target_rect_changed.connect(_on_tutorial_target_rect_changed)
	
	# Ждем ровно 0.5 секунды после загрузки сцены и вызываем стартовый диалог.
	get_tree().create_timer(0.5, true, false, true).timeout.connect(_on_game_started)

# ========== ЛОГИКА ОЧЕРЕДИ ==========
func _queue_dialog(steps: Array[String]) -> void:
	if steps.is_empty(): 
		return
	dialog_queue.append(steps)
	if not visible:
		_play_next_dialog()

func _play_next_dialog() -> void:
	if dialog_queue.is_empty():
		_hide_and_unpause()
		return
		
	if not _pause_applied:
		_pause_state_before_tutorial = get_tree().paused
		get_tree().paused = true
		_pause_applied = true
		
	tutorial_steps = dialog_queue.pop_front()
	current_step = 0
	show()
	_show_current_step()

func _hide_and_unpause() -> void:
	hide()
	_clear_focus_target()
	_destroy_focus_cutout()
	if _pause_applied:
		get_tree().paused = _pause_state_before_tutorial
		_pause_applied = false

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_play_next_dialog()
		return

	# Включаем защиту от случайных кликов на 0.5 секунд
	_is_input_blocked = true
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): _is_input_blocked = false)

	# Сбрасываем цвет перед новой репликой
	dialog_text.modulate = Color.WHITE
	if highlight_tween:
		highlight_tween.kill()

	_apply_focus_for_current_step()

	is_typing = true
	dialog_text.text = tutorial_steps[current_step]
	dialog_text.visible_ratio = 0.0 
	
	if typing_tween: 
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = tutorial_steps[current_step].length() * 0.03
	typing_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(func(): 
		is_typing = false
		_start_highlight_animation()
	)

func _start_highlight_animation() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.set_ease(Tween.EASE_IN_OUT)
	highlight_tween.set_trans(Tween.TRANS_SINE)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.2, 1.2, 1.2), 1.0)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.0, 1.0, 1.0), 1.0)

# ========== РЕАКЦИИ НА ИГРОВЫЕ СОБЫТИЯ ==========
func _on_game_started() -> void:
	_queue_dialog(intro_steps)
	_queue_dialog(gathering_steps)

func _on_raider_spawned(_position: Vector2) -> void:
	if _raider_warning_shown: 
		return
	_raider_warning_shown = true
	await get_tree().create_timer(1.5, true, false, true).timeout
	_queue_dialog(raider_warning_steps)

func _on_resource_changed(type: String, new_amount: int) -> void:
	if type == "metal":
		if new_amount >= 75 and not _shop_invite_shown:
			_shop_invite_shown = true
			_queue_dialog(shop_invite_steps)
			
		if new_amount >= 375 and not _reactor_guide_shown:
			_reactor_guide_shown = true
			_queue_dialog(reactor_guide_steps)

func _on_shop_opened() -> void:
	if not _shop_guide_shown and ResourceManager.metal >= 75:
		_shop_guide_shown = true
		_queue_dialog(shop_guide_steps)

func _on_max_resources_reached(resource_type: String, _max_amount: int) -> void:
	if _max_resources_shown_times < 2:
		_max_resources_shown_times += 1
		print("DEBUG: Max resources reached times: ", _max_resources_shown_times)
		_queue_dialog(max_resources_steps)

func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	if _raider_warning_shown and not _raider_defense_shown:
		_raider_defense_shown = true
		_queue_dialog(raider_defense_steps)

func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome == "lose":
		var defeat_steps: Array[String] = [
			"КАПИТАН, МЫ ПОТЕРПЕЛИ ПОРАЖЕНИЕ! АКТИВИРУЮ РЕЖИМ ПОСЛЕДНЕЙ НАДЕЖДЫ...",
		]
		dialog_queue.clear()
		_queue_dialog(defeat_steps)

# ========== ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ ==========
func _input(event: InputEvent) -> void:
	if not visible: 
		return

	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Перехватываем событие, чтобы оно не просочилось в саму игру под окном Нади
		get_viewport().set_input_as_handled() 
		
		# Если блокировка активна - игнорируем нажатие (но в игру оно уже не пойдет благодаря строке выше)
		if _is_input_blocked:
			return
		
		if is_typing:
			if typing_tween: 
				typing_tween.kill()
			dialog_text.visible_ratio = 1.0
			is_typing = false
			_start_highlight_animation()
		else:
			if _step_allows_target_interaction:
				if not _can_trigger_step_action(_extract_event_position(event)):
					return
				if not _step_action_id.is_empty():
					GameEvents.tutorial_action_requested.emit(_step_action_id)

			current_step += 1
			_show_current_step()

func _apply_focus_for_current_step() -> void:
	_clear_focus_target()

	if tutorial_steps == shop_invite_steps and current_step == 0:
		_set_focus_target("shop_button", Color(0.756863, 0.564706, 0.87451, 1.0), true, "open_shop")
		return

	if tutorial_steps != shop_guide_steps:
		return

	match current_step:
		1:
			_set_focus_target("hull", Color(0.3, 0.8, 0.3, 1.0), false)
		2:
			_set_focus_target("reactor", Color(0.95, 0.74, 0.2, 1.0), false)
		3:
			_set_focus_target("reactor", Color(0.95, 0.74, 0.2, 1.0), false)
		4:
			_set_focus_target("core", Color(0.941, 0.816, 0.125, 1.0), false)
		5:
			_set_focus_target("collector", Color(1.0, 0.9, 0.2, 1.0), false)
		6:
			_set_focus_target("turret", Color(0.95, 0.32, 0.18, 1.0), false)
		7:
			_set_focus_target("core", Color(0.941, 0.816, 0.125, 1.0), false)
		8:
			_set_focus_target("hull", Color(0.3, 0.8, 0.3, 1.0), true, "buy_hull")

func _set_focus_target(target_id: String, accent_color: Color, allow_interaction: bool, action_id: String = "") -> void:
	_focused_target_id = target_id
	_step_allows_target_interaction = allow_interaction
	_step_action_id = action_id
	_focused_target_rect = Rect2()
	overlay.color = Color(0.102, 0.051, 0.208, 0.0)
	GameEvents.tutorial_focus_changed.emit(target_id, accent_color, allow_interaction)

func _clear_focus_target() -> void:
	_focused_target_id = ""
	_focused_target_rect = Rect2()
	_step_allows_target_interaction = false
	_step_action_id = ""
	overlay.color = Color(0.102, 0.051, 0.208, 0.8)
	_destroy_focus_cutout()
	GameEvents.tutorial_focus_cleared.emit()

func _on_tutorial_target_rect_changed(target_id: String, target_rect: Rect2) -> void:
	if target_id != _focused_target_id:
		return
	_focused_target_rect = target_rect
	_update_focus_cutout()

func _can_trigger_step_action(event_position: Vector2) -> bool:
	if _focused_target_id.is_empty():
		return false
	if _focused_target_rect.size.x <= 0.0 or _focused_target_rect.size.y <= 0.0:
		return false
	return _focused_target_rect.has_point(event_position)

func _extract_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	return Vector2(-10000.0, -10000.0)

func _create_cutout_layer() -> void:
	_cutout_layer = CanvasLayer.new()
	_cutout_layer.layer = 1
	add_child(_cutout_layer)

func _create_focus_cutout() -> void:
	_destroy_focus_cutout()
	if _focused_target_rect.size.x <= 0.0 or _focused_target_rect.size.y <= 0.0:
		return

	var viewport_rect = get_viewport().get_visible_rect()
	var viewport_size = viewport_rect.size
	
	var padding = 0
	var target_top = max(0, _focused_target_rect.position.y - padding)
	var target_left = max(0, _focused_target_rect.position.x - padding)
	var target_right = min(viewport_size.x, _focused_target_rect.position.x + _focused_target_rect.size.x + padding)
	var target_bottom = min(viewport_size.y, _focused_target_rect.position.y + _focused_target_rect.size.y + padding)

	var rects_to_draw = [
		Rect2(0, 0, viewport_size.x, target_top),
		Rect2(0, target_bottom, viewport_size.x, viewport_size.y - target_bottom),
		Rect2(0, target_top, target_left, target_bottom - target_top),
		Rect2(target_right, target_top, viewport_size.x - target_right, target_bottom - target_top),
	]

	for rect in rects_to_draw:
		if rect.size.x > 0 and rect.size.y > 0:
			var panel = ColorRect.new()
			panel.color = Color(0.102, 0.051, 0.208, 0.8)
			panel.anchor_left = 0.0
			panel.anchor_top = 0.0
			panel.anchor_right = 0.0
			panel.anchor_bottom = 0.0
			panel.offset_left = rect.position.x
			panel.offset_top = rect.position.y
			panel.offset_right = rect.position.x + rect.size.x
			panel.offset_bottom = rect.position.y + rect.size.y
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_cutout_layer.add_child(panel)
			_focus_cutout_panels.append(panel)

func _update_focus_cutout() -> void:
	_create_focus_cutout()

func _destroy_focus_cutout() -> void:
	for panel in _focus_cutout_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_focus_cutout_panels.clear()
