extends CanvasLayer
## Экран настроек: громкость музыки/звуков и быстрый переход в обучение.

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var btn_training: Button = %BtnTraining
@onready var btn_back: Button = %BtnBack

const START_MENU_SCENE: String = "res://ui/start_menu.tscn"
const TRAINING_SCENE: String = "res://ui/tutorial_first_call_mode.tscn"


func _ready() -> void:
	_configure_slider(music_slider)
	_configure_slider(sfx_slider)

	var music_volume: float = AudioManager.get_music_volume()
	var sfx_volume: float = AudioManager.get_sfx_volume()
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	_update_value_labels()

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_slider.drag_ended.connect(_on_sfx_slider_drag_ended)
	btn_training.pressed.connect(_on_btn_training_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)


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


func _on_btn_training_pressed() -> void:
	if not ResourceLoader.exists(TRAINING_SCENE):
		push_warning("Training scene not found: %s" % TRAINING_SCENE)
		return
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(TRAINING_SCENE)


func _on_btn_back_pressed() -> void:
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(START_MENU_SCENE)
