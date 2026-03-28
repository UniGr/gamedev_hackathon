extends Button

const MAIN_SCENE_PRIMARY: String = "res://main.tscn"
const MAIN_SCENE_FALLBACK: String = "res://universal/main.tscn"

func _ready() -> void:
	# Эта проверка сработает сразу при запуске
	print("Кнопка 'ИГРАТЬ' инициализирована!")
	
	# Подключаем сигнал нажатия к самой себе
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("--- КЛИК ПОДТВЕРЖДЕН ВНУТРИ КНОПКИ ---")
	var target_scene: String = MAIN_SCENE_PRIMARY if ResourceLoader.exists(MAIN_SCENE_PRIMARY) else MAIN_SCENE_FALLBACK
	get_tree().change_scene_to_file(target_scene)

# Визуальная проверка: кнопка будет печатать в консоль при наведении
func _on_mouse_entered() -> void:
	print("Мышка над кнопкой!")
