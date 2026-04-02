extends CanvasLayer
## Стартовое меню игры.
## Предоставляет кнопки для запуска игры, настроек и выхода.

@onready var btn_start: Button = %BtnStart
@onready var btn_settings: Button = %BtnSettings
@onready var btn_exit: Button = %BtnExit

const MAIN_SCENE_PRIMARY: String = "res://main.tscn"
const MAIN_SCENE_FALLBACK: String = "res://universal/main.tscn"
const SETTINGS_SCENE: String = "res://ui/settings_menu.tscn"


func _ready() -> void:
	_configure_button_pivot(btn_start)
	_configure_button_pivot(btn_settings)
	_configure_button_pivot(btn_exit)
	btn_start.resized.connect(_on_button_resized.bind(btn_start))
	btn_settings.resized.connect(_on_button_resized.bind(btn_settings))
	btn_exit.resized.connect(_on_button_resized.bind(btn_exit))
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	
	# Анимации hover
	btn_start.mouse_entered.connect(_on_btn_hover.bind(btn_start, true))
	btn_start.mouse_exited.connect(_on_btn_hover.bind(btn_start, false))
	btn_settings.mouse_entered.connect(_on_btn_hover.bind(btn_settings, true))
	btn_settings.mouse_exited.connect(_on_btn_hover.bind(btn_settings, false))
	btn_exit.mouse_entered.connect(_on_btn_hover.bind(btn_exit, true))
	btn_exit.mouse_exited.connect(_on_btn_hover.bind(btn_exit, false))
	
	_start_pulse_animation()


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
