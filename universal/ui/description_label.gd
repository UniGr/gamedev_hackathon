extends Label
class_name DescriptionLabel

# Auto-assigns label text from central module descriptions registry.
@export var description_key: String = ""
@export var fallback_text: String = ""

func _ready() -> void:
	var descs := preload("res://core/module_descriptions.gd").DESCRIPTIONS
	var final_text: String = descs.get(description_key, "")
	if final_text == "" and fallback_text != "":
		final_text = fallback_text
	text = final_text
