extends Node
class_name RaiderAnimationComponent
## Компонент покадровой анимации для рейдера.
## Загружает кадры по базовому пути ({base}1.png … {base}N.png)
## и циклически переключает текстуру целевого Sprite2D.

var _sprite: Sprite2D
var _frames: Array[Texture2D] = []
var _fps: float = 10.0
var _current_frame: int = 0
var _time_accumulator: float = 0.0
var _active: bool = false


func configure(sprite: Sprite2D, base_path: String, frame_count: int, fps: float) -> void:
	_sprite = sprite
	_fps = maxf(1.0, fps)
	_current_frame = 0
	_time_accumulator = 0.0
	_frames = _load_frames(base_path, frame_count)
	_active = not _frames.is_empty() and _sprite != null
	if _active:
		_apply_frame()


func stop() -> void:
	_active = false


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return
	_time_accumulator += delta
	var frame_duration: float = 1.0 / _fps
	while _time_accumulator >= frame_duration:
		_time_accumulator -= frame_duration
		_current_frame = (_current_frame + 1) % _frames.size()
	_apply_frame()


func _apply_frame() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		_active = false
		return
	if _current_frame < _frames.size():
		_sprite.texture = _frames[_current_frame]


func _load_frames(base_path: String, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if base_path.is_empty() or count <= 0:
		return frames
	for i in range(1, count + 1):
		var path: String = "%s%d.png" % [base_path, i]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				frames.append(tex)
	return frames
