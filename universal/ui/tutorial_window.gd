extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это Н.А.Д.Я., ваш бортовой ИИ.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему мусору, чтобы добыть МЕТАЛЛ!",
	"Используйте МЕТАЛЛ для постройки модулей. Постройте Сборщик, и он начнет собирать мусор автоматически.",
	"Отлично! Теперь нажмите на кнопку МАГАЗИН, чтобы открыть меню покупок.",
	"В магазине вы можете купить модули: Корпус, Реактор, Сборщик, Турель. Начните с Корпуса за 5 МЕТАЛЛ.",
	"Удачи, Капитан! Собирайте ресурсы, стройте и обороняйтесь. Н.А.Д.Я. всегда рядом."
]


var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это вражеский налётчик. Он хочет забрать наши ресурсы.",
	"Чтобы отбиться, кликайте прямо по врагу, как по мусору.",
	"Для автоматизации постройте турели: их можно купить в магазине."
]

var tutorial_steps: Array[String] = []

var current_step: int = 0
var is_typing: bool = false
var typing_tween: Tween
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _pending_raider_warning: bool = false
var shop_opened: bool = false

func _ready() -> void:
	# Диалог должен оставаться интерактивным даже когда игра на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() 
	GameEvents.game_started.connect(start_tutorial)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.shop_opened.connect(_on_shop_opened)
	GameEvents.shop_closed.connect(_on_shop_closed)
	# Мы удалили старую подписку на gui_input, теперь все работает через _input()

func start_tutorial() -> void:
	_start_dialog(intro_steps)


func _start_dialog(steps: Array[String]) -> void:
	if steps.is_empty():
		return

	if not _pause_applied:
		_pause_state_before_tutorial = get_tree().paused
		get_tree().paused = true
		_pause_applied = true

	tutorial_steps = steps
	show()
	current_step = 0
	_show_current_step()


func _on_raider_spawned(_position: Vector2) -> void:
	if _raider_warning_shown:
		return

	_raider_warning_shown = true
	if visible:
		_pending_raider_warning = true
		return
	# Небольшая задержка, чтобы игрок успел увидеть появление врага
	await get_tree().create_timer(1.5).timeout
	# Если за это время открылся другой диалог — поставим предупреждение в очередь
	if visible:
		_pending_raider_warning = true
		return

	_start_dialog(raider_warning_steps)

func _on_resource_changed(type: String, new_amount: int) -> void:
	# Логика для интерактивных шагов, если нужно
	pass

func _on_shop_opened() -> void:
	shop_opened = true
	# Если ждем открытия магазина, перейти к следующему шагу
	if visible and current_step == 4:  # После шага о нажатии на магазин
		current_step += 1
		_show_current_step()

func _on_shop_closed() -> void:
	shop_opened = false

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_end_tutorial()
		return

	is_typing = true
	var text = tutorial_steps[current_step]
	text = _add_highlight_animation(text)
	dialog_text.text = text
	dialog_text.visible_ratio = 0.0 # Сбрасываем видимость текста в ноль
	
	if typing_tween:
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = tutorial_steps[current_step].length() * 0.03
	typing_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(func(): 
		is_typing = false
		_start_highlight_animation()
	)

func _add_highlight_animation(text: String) -> String:
	# Выделяем слова капсом и цветом
	text = text.replace("Н.А.Д.Я.", "[color=yellow][b]Н.А.Д.Я.[/b][/color]")
	text = text.replace("МЕТАЛЛ", "[color=orange][b]МЕТАЛЛ[/b][/color]")
	text = text.replace("ВРАГИ", "[color=red][b]ВРАГИ[/b][/color]")
	text = text.replace("ВРАГАМ", "[color=red][b]ВРАГАМ[/b][/color]")
	return text

func _start_highlight_animation() -> void:
	# Простая пульсация для выделенных слов (анимация цвета)
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Анимируем modulate для всего текста (простая пульсация)
	tween.tween_property(dialog_text, "modulate", Color(1.2, 1.2, 1.2), 1.0)
	tween.tween_property(dialog_text, "modulate", Color(1.0, 1.0, 1.0), 1.0)

func _end_tutorial() -> void:
	hide()
	if _pause_applied:
		get_tree().paused = _pause_state_before_tutorial
		_pause_applied = false
	print("Обучение завершено!")
	if _pending_raider_warning:
		_pending_raider_warning = false
		_start_dialog(raider_warning_steps)
	# Здесь можно запустить спавн мусора/врагов

# ==========================================
# ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ
# ==========================================
func _input(event: InputEvent) -> void:
	# Если Надя спрятана, мы вообще не вмешиваемся в клики
	if not visible:
		return

	# Проверяем, что это левый клик мыши или тап по экрану смартфона
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# МАГИЯ: Забираем клик себе! Теперь он не пройдет сквозь интерфейс в игру.
		get_viewport().set_input_as_handled() 
		
		if is_typing:
			# Если текст еще печатается - моментально показываем его весь
			if typing_tween:
				typing_tween.kill()
			dialog_text.visible_ratio = 1.0
			is_typing = false
		else:
			# Если текст уже напечатан - идем к следующей реплике
			current_step += 1
			_show_current_step()
