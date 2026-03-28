extends Node

@export var scroll_speed: float = 100.0

func _process(delta: float) -> void:
	if get_parent() is ParallaxBackground:
		get_parent().scroll_offset.y += scroll_speed * delta
