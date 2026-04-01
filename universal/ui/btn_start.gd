extends Button
## Кнопка запуска игры из стартового меню.
## Переключает на основную игровую сцену.

const MAIN_SCENE_PRIMARY: String = "res://main.tscn"
const MAIN_SCENE_FALLBACK: String = "res://universal/main.tscn"


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	var target_scene: String = MAIN_SCENE_PRIMARY if ResourceLoader.exists(MAIN_SCENE_PRIMARY) else MAIN_SCENE_FALLBACK
	get_tree().change_scene_to_file(target_scene)
