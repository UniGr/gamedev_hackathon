extends CanvasLayer
## Стартовое меню игры.
## Предоставляет кнопки для запуска игры, настроек и выхода.

@onready var btn_start: Button = %BtnStart
@onready var btn_endless: Button = %BtnEndless
@onready var btn_settings: Button = %BtnSettings
@onready var btn_exit: Button = %BtnExit

const MAIN_SCENE_PRIMARY: String = "res://main.tscn"
const MAIN_SCENE_FALLBACK: String = "res://universal/main.tscn"
const SETTINGS_SCENE: String = "res://ui/settings_menu.tscn"

const LOCKED_HINT: String = "Сначала пройдите обычный режим"
const LOCK_ICON_PATH: String = "res://assets/lock_icon.png"

@onready var _content_root: Control = $Control

## Приглушённый цвет текста заблокированной кнопки бесконечного режима.
const ENDLESS_LOCKED_FONT_COLOR: Color = Color(0.639, 0.612, 0.71, 1)

## Равный отступ: граница→иконка и иконка→текст в заблокированном состоянии.
const ENDLESS_LOCK_GAP: int = 44

## Исходные стили кнопки бесконечного режима (для восстановления после разблокировки).
var _endless_styles: Dictionary = {}
var _snackbar: Control = null


func _ready() -> void:
	_configure_button_pivot(btn_start)
	_configure_button_pivot(btn_endless)
	_configure_button_pivot(btn_settings)
	_configure_button_pivot(btn_exit)
	btn_start.resized.connect(_on_button_resized.bind(btn_start))
	btn_endless.resized.connect(_on_button_resized.bind(btn_endless))
	btn_settings.resized.connect(_on_button_resized.bind(btn_settings))
	btn_exit.resized.connect(_on_button_resized.bind(btn_exit))

	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_endless.pressed.connect(_on_btn_endless_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)

	# Анимации hover
	btn_endless.mouse_entered.connect(_on_btn_hover.bind(btn_endless, true))
	btn_endless.mouse_exited.connect(_on_btn_hover.bind(btn_endless, false))
	btn_start.mouse_entered.connect(_on_btn_hover.bind(btn_start, true))
	btn_start.mouse_exited.connect(_on_btn_hover.bind(btn_start, false))
	btn_settings.mouse_entered.connect(_on_btn_hover.bind(btn_settings, true))
	btn_settings.mouse_exited.connect(_on_btn_hover.bind(btn_settings, false))
	btn_exit.mouse_entered.connect(_on_btn_hover.bind(btn_exit, true))
	btn_exit.mouse_exited.connect(_on_btn_hover.bind(btn_exit, false))
	
	_start_pulse_animation()
	_cache_endless_styles()
	_refresh_endless_lock()
	GameMode.endless_unlocked.connect(_refresh_endless_lock)


func _cache_endless_styles() -> void:
	_endless_styles = {
		"normal": btn_endless.get_theme_stylebox("normal"),
		"hover": btn_endless.get_theme_stylebox("hover"),
		"pressed": btn_endless.get_theme_stylebox("pressed"),
		"font_color": btn_endless.get_theme_color("font_color"),
	}


## Бесконечный режим доступен только после первого прохождения обычного режима.
## Кнопка остаётся интерактивной (ловит нажатие ради подсказки), но в заблокированном
## состоянии выглядит приглушённой и помечена символом замка.
func _refresh_endless_lock() -> void:
	btn_endless.tooltip_text = ""
	# Пиксель-арт иконки не должен размываться.
	btn_endless.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn_endless.expand_icon = true
	btn_endless.add_theme_constant_override("icon_max_width", 56)
	if GameMode.is_endless_unlocked():
		btn_endless.text = "∞ БЕСКОНЕЧНЫЙ"
		btn_endless.icon = null
		btn_endless.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_endless.add_theme_stylebox_override("normal", _endless_styles["normal"])
		btn_endless.add_theme_stylebox_override("hover", _endless_styles["hover"])
		btn_endless.add_theme_stylebox_override("pressed", _endless_styles["pressed"])
		btn_endless.add_theme_color_override("font_color", _endless_styles["font_color"])
	else:
		btn_endless.text = "БЕСКОНЕЧНЫЙ"
		btn_endless.icon = load(LOCK_ICON_PATH)
		# Схема: граница — GAP — иконка — GAP — текст — ... — граница.
		# Левый внутренний отступ == отступ между иконкой и текстом.
		btn_endless.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_endless.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_endless.add_theme_constant_override("h_separation", ENDLESS_LOCK_GAP)
		var locked_style: StyleBoxFlat = _make_locked_style()
		locked_style.content_margin_left = ENDLESS_LOCK_GAP
		btn_endless.add_theme_stylebox_override("normal", locked_style)
		btn_endless.add_theme_stylebox_override("hover", locked_style)
		btn_endless.add_theme_stylebox_override("pressed", locked_style)
		btn_endless.add_theme_color_override("font_color", ENDLESS_LOCKED_FONT_COLOR)


func _make_locked_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.129, 0.098, 0.18, 1)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.435, 0.396, 0.541, 1)
	return style


func _configure_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_button_resized(button: Button) -> void:
	_configure_button_pivot(button)


func _start_pulse_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn_start, "modulate:a", 0.7, 1.5)
	tween.tween_property(btn_start, "modulate:a", 1.0, 1.5)


func _on_btn_start_pressed() -> void:
	GameMode.set_mode(GameMode.Mode.NORMAL)
	_launch_game()


func _on_btn_endless_pressed() -> void:
	if not GameMode.is_endless_unlocked():
		_show_snackbar(LOCKED_HINT)
		return
	GameMode.set_mode(GameMode.Mode.ENDLESS)
	_launch_game()


## Показывает всплывающее уведомление (снэкбар) внизу экрана.
func _show_snackbar(message: String) -> void:
	if is_instance_valid(_snackbar):
		_snackbar.queue_free()

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.164, 0.082, 0.302, 0.96)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.4, 0.8, 1.0, 1)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 20
	style.content_margin_bottom = 20

	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.0
	panel.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", btn_endless.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.941, 0.875, 1, 1))
	panel.add_child(label)

	_content_root.add_child(panel)
	_snackbar = panel

	panel.reset_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.position = Vector2(
		(viewport_size.x - panel.size.x) * 0.5,
		viewport_size.y - panel.size.y - 200.0
	)

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(panel.queue_free)


func _launch_game() -> void:
	var target_scene: String = MAIN_SCENE_PRIMARY if ResourceLoader.exists(MAIN_SCENE_PRIMARY) else MAIN_SCENE_FALLBACK
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(target_scene)


func _on_btn_settings_pressed() -> void:
	if not ResourceLoader.exists(SETTINGS_SCENE):
		push_warning("Settings scene not found: %s" % SETTINGS_SCENE)
		return
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()


func _on_btn_hover(button: Button, entered: bool) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	if entered:
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
