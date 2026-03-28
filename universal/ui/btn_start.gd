extends Button

func _ready() -> void:
	# Эта проверка сработает сразу при запуске
	print("Кнопка 'ИГРАТЬ' инициализирована!")
	
	# Подключаем сигнал нажатия к самой себе
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("--- КЛИК ПОДТВЕРЖДЕН ВНУТРИ КНОПКИ ---")
	get_tree().change_scene_to_file("res://main.tscn")

# Визуальная проверка: кнопка будет печатать в консоль при наведении
func _on_mouse_entered() -> void:
	print("Мышка над кнопкой!")
