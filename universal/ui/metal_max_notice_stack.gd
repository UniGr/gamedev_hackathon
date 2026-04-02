extends VBoxContainer
class_name MetalMaxNoticeStack

const DEFAULT_NOTICE_TEXT: String = "ЛИМИТ МЕТАЛЛА ДОСТИГНУТ"

@export var notice_lifetime_sec: float = 4.0
@export var notice_font_size: int = 28
@export var notice_stack_spacing: int = 20
@export var notice_text_color: Color = Color(0.956, 0.349, 0.349, 1.0)
@export var notice_panel_color: Color = Color(0.05, 0.03, 0.03, 1.0)
@export var notice_border_color: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var notice_border_width: int = 3
@export var notice_padding_left: int = 20
@export var notice_padding_top: int = 20
@export var notice_padding_right: int = 20
@export var notice_padding_bottom: int = 20
@export var notice_show_duration_sec: float = 0.5
@export var notice_hide_duration_sec: float = 0.5

var _label_settings: LabelSettings = LabelSettings.new()
var _panel_style: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", notice_stack_spacing)
	_configure_styles()


func set_notice_font(font: Font) -> void:
	_label_settings.font = font
	_label_settings.font_size = notice_font_size
	_label_settings.font_color = notice_text_color


func show_notice(message: String = DEFAULT_NOTICE_TEXT) -> void:
	var target_height: float = _get_notice_min_height()

	var notice_panel: PanelContainer = PanelContainer.new()
	notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_panel.custom_minimum_size = Vector2(0.0, 0.0)
	notice_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	notice_panel.add_theme_stylebox_override("panel", _panel_style)

	var padding: MarginContainer = MarginContainer.new()
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padding.add_theme_constant_override("margin_left", notice_padding_left)
	padding.add_theme_constant_override("margin_top", notice_padding_top)
	padding.add_theme_constant_override("margin_right", notice_padding_right)
	padding.add_theme_constant_override("margin_bottom", notice_padding_bottom)

	var notice_label: Label = Label.new()
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	notice_label.text = message
	notice_label.label_settings = _label_settings

	padding.add_child(notice_label)
	notice_panel.add_child(padding)
	add_child(notice_panel)

	var show_tween: Tween = get_tree().create_tween()
	show_tween.set_trans(Tween.TRANS_CUBIC)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.parallel().tween_property(notice_panel, "modulate:a", 1.0, notice_show_duration_sec)
	show_tween.parallel().tween_property(notice_panel, "custom_minimum_size", Vector2(0.0, target_height), notice_show_duration_sec)

	var expiration_timer: SceneTreeTimer = get_tree().create_timer(notice_lifetime_sec, true, false, true)
	expiration_timer.timeout.connect(func() -> void:
		_animate_notice_out_and_free(notice_panel)
	)


func _animate_notice_out_and_free(notice_panel: PanelContainer) -> void:
	if not is_instance_valid(notice_panel):
		return

	var hide_tween: Tween = get_tree().create_tween()
	hide_tween.set_trans(Tween.TRANS_CUBIC)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.parallel().tween_property(notice_panel, "modulate:a", 0.0, notice_hide_duration_sec)
	hide_tween.parallel().tween_property(notice_panel, "custom_minimum_size", Vector2(0.0, 0.0), notice_hide_duration_sec)
	await hide_tween.finished

	if is_instance_valid(notice_panel):
		notice_panel.queue_free()


func _get_notice_min_height() -> float:
	var text_height: float = float(max(14, notice_font_size))
	var vertical_padding: float = float(notice_padding_top + notice_padding_bottom)
	var border_height: float = float(notice_border_width * 2)
	return text_height + vertical_padding + border_height


func _configure_styles() -> void:
	_panel_style.bg_color = notice_panel_color
	_panel_style.border_color = notice_border_color
	_panel_style.border_width_left = notice_border_width
	_panel_style.border_width_top = notice_border_width
	_panel_style.border_width_right = notice_border_width
	_panel_style.border_width_bottom = notice_border_width
	_panel_style.corner_radius_top_left = 0
	_panel_style.corner_radius_top_right = 0
	_panel_style.corner_radius_bottom_left = 0
	_panel_style.corner_radius_bottom_right = 0
	_panel_style.content_margin_left = 0
	_panel_style.content_margin_top = 0
	_panel_style.content_margin_right = 0
	_panel_style.content_margin_bottom = 0

	_label_settings.font_size = notice_font_size
	_label_settings.font_color = notice_text_color