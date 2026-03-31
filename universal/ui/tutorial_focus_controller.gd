extends RefCounted
class_name TutorialFocusController

const TUTORIAL_FOCUS_PULSE: Color = Color(6.5, 6.5, 6.5, 1.0)
const TUTORIAL_FOCUS_BASE_BOOST: float = 2.2

var _tutorial_target_controls: Dictionary = {}
var _tutorial_focused_control: Control
var _tutorial_focus_tween: Tween


func register_targets(targets: Dictionary) -> void:
	_tutorial_target_controls = targets


func clear_focus() -> void:
	if _tutorial_focus_tween:
		_tutorial_focus_tween.kill()
		_tutorial_focus_tween = null
	if _tutorial_focused_control and is_instance_valid(_tutorial_focused_control):
		_tutorial_focused_control.modulate = Color.WHITE
	_tutorial_focused_control = null


func process_focus_tracking() -> void:
	if _tutorial_focused_control == null:
		return
	if not is_instance_valid(_tutorial_focused_control):
		return
	if not _tutorial_focused_control.visible:
		return
	GameEvents.tutorial_target_rect_changed.emit(get_focused_target_id(), _tutorial_focused_control.get_global_rect())


func focus_target(target_id: String, accent_color: Color) -> void:
	clear_focus()
	if not _tutorial_target_controls.has(target_id):
		return

	var target: Variant = _tutorial_target_controls[target_id]
	if not (target is Control):
		return

	_tutorial_focused_control = target as Control
	if not _tutorial_focused_control.visible:
		return

	var boosted_focus_color: Color = Color(
		accent_color.r * TUTORIAL_FOCUS_BASE_BOOST,
		accent_color.g * TUTORIAL_FOCUS_BASE_BOOST,
		accent_color.b * TUTORIAL_FOCUS_BASE_BOOST,
		1.0
	)

	_tutorial_focused_control.modulate = boosted_focus_color
	_tutorial_focus_tween = _tutorial_focused_control.create_tween()
	_tutorial_focus_tween.set_loops()
	_tutorial_focus_tween.set_trans(Tween.TRANS_SINE)
	_tutorial_focus_tween.set_ease(Tween.EASE_IN_OUT)
	_tutorial_focus_tween.tween_property(_tutorial_focused_control, "modulate", TUTORIAL_FOCUS_PULSE, 0.3)
	_tutorial_focus_tween.tween_property(_tutorial_focused_control, "modulate", boosted_focus_color, 0.3)

	GameEvents.tutorial_target_rect_changed.emit(target_id, _tutorial_focused_control.get_global_rect())


func get_focused_target_id() -> String:
	for id in _tutorial_target_controls.keys():
		if _tutorial_target_controls[id] == _tutorial_focused_control:
			return str(id)
	return ""
