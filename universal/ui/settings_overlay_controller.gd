extends ColorRect
class_name SettingsOverlayController
## Настройки в виде оверлея поверх текущего экрана.
## Содержит: громкость музыки/звуков, выход в меню.

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var btn_main_menu: Button = %BtnMainMenu
@onready var btn_back: Button = %BtnBack
@onready var confirm_overlay: ColorRect = %ConfirmOverlay
@onready var btn_confirm_yes: Button = %BtnYes
@onready var btn_confirm_no: Button = %BtnNo

const START_MENU_SCENE: String = "res://ui/start_menu.tscn"

var _was_paused_before: bool = false


func _ready() -> void:
	visible = false
	confirm_overlay.visible = false
	_configure_slider(music_slider)
	_configure_slider(sfx_slider)

	var music_vol: float = AudioManager.get_music_volume()
	var sfx_vol: float = AudioManager.get_sfx_volume()
	music_slider.value = music_vol
	sfx_slider.value = sfx_vol
	_update_value_labels()

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_slider.drag_ended.connect(_on_sfx_slider_drag_ended)
	btn_main_menu.pressed.connect(_on_btn_main_menu_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)
	btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)
	btn_confirm_no.pressed.connect(_on_confirm_no_pressed)


func open() -> void:
	var music_vol: float = AudioManager.get_music_volume()
	var sfx_vol: float = AudioManager.get_sfx_volume()
	music_slider.value = music_vol
	sfx_slider.value = sfx_vol
	_update_value_labels()
	visible = true
	_was_paused_before = get_tree().paused
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = _was_paused_before


func _configure_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01


func _on_music_slider_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_update_value_labels()


func _on_sfx_slider_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	_update_value_labels()


func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	if not value_changed:
		return
	AudioManager.play_ui_open()


func _update_value_labels() -> void:
	music_value_label.text = "%d%%" % int(roundf(music_slider.value * 100.0))
	sfx_value_label.text = "%d%%" % int(roundf(sfx_slider.value * 100.0))


func _on_btn_main_menu_pressed() -> void:
	AudioManager.play_ui_open()
	confirm_overlay.visible = true


func _on_confirm_yes_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(START_MENU_SCENE)


func _on_confirm_no_pressed() -> void:
	AudioManager.play_ui_open()
	confirm_overlay.visible = false


func _on_btn_back_pressed() -> void:
	AudioManager.play_ui_open()
	close()
