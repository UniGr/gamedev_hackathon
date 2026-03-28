extends Node
## Глобальный менеджер звука (Autoload: SoundManager)

# Подгружаем ассеты
const SOUND_CLICK = preload("res://assets/sounds/click.wav")
const SOUND_BUILD = preload("res://assets/sounds/build.wav")
const SOUND_GARBAGE = preload("res://assets/sounds/garbage.wav")

func _ready() -> void:
	# Слушаем глобальные события игры
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	GameEvents.module_built.connect(_on_module_built)
	
	# Можно также слушать начало игры
	GameEvents.game_started.connect(_on_game_started)
	
	print("SoundManager Initialized")

func play_sfx(stream: AudioStream, pitch_variation: float = 0.1) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	# Добавляем небольшую вариацию тона, чтобы звук не надоедал
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	add_child(player)
	player.play()
	# Удаляем плеер после завершения звука
	player.finished.connect(player.queue_free)

func _on_garbage_clicked(_amount: int) -> void:
	play_sfx(SOUND_GARBAGE, 0.2)

func _on_module_built(_type: String, _pos: Vector2) -> void:
	play_sfx(SOUND_BUILD, 0.05)

func _on_game_started() -> void:
	play_sfx(SOUND_CLICK)

# Функция для кнопок (вызывай её в UI коде)
func play_button_click() -> void:
	play_sfx(SOUND_CLICK, 0.1)
