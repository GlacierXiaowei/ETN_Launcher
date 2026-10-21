extends Control
class_name GlassIconPanel

signal pressed

enum ButtonType { PRIMARY, SECONDARY, THIRD }
enum ContentType { TEXT, ICON }

@export_group("Content")
@export var content_type: ContentType = ContentType.TEXT:
	set(v):
		content_type = v
		_rebuild_content()

@export var text: String = "×":
	set(v):
		text = v
		if _label != null:
			_label.text = v

@export var font_size: int = 20:
	set(v):
		font_size = v
		if _label != null:
			_label.add_theme_font_size_override("font_size", v)

@export var icon: Texture2D:
	set(v):
		icon = v
		if _icon_rect != null:
			_icon_rect.texture = v

@export var icon_scale: float = 0.5:
	set(v):
		icon_scale = v
		_update_icon_size()

@export_group("State")
@export var disabled: bool = false:
	set(v):
		disabled = v
		if _hit_button != null:
			_hit_button.disabled = v
		_update_glass_state()

@export var is_selected: bool = false:
	set(v):
		is_selected = v
		_is_pressed = v
		_update_glass_state()

@export var page_index: int = 0

@export_group("Button Style")
@export var button_type: ButtonType = ButtonType.SECONDARY:
	set(v):
		button_type = v
		_update_glass_state()

@export_group("Glass Effect")
@export var corner_radius_px: float = 24.0:
	set(v):
		corner_radius_px = v
		_update_glass_state()

var _glass_bg: ColorRect
var _label: Label
var _icon_rect: TextureRect
var _hit_button: Button
var _is_hover := false
var _is_pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	
	if custom_minimum_size.x <= 0 or custom_minimum_size.y <= 0:
		custom_minimum_size = Vector2(48, 48)
	
	_build_nodes()
	_rebuild_content()
	
	resized.connect(_on_resized)
	await get_tree().process_frame
	_update_layout()
	_update_glass_state()

func _build_nodes() -> void:
	_glass_bg = ColorRect.new()
	_glass_bg.name = "GlassBackground"
	_glass_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass_bg.color = Color(1, 1, 1, 1)
	add_child(_glass_bg)
	
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
	if mat.shader == null:
		push_error("[GlassIconPanel] Failed to load shader")
	_glass_bg.material = mat
	
	_hit_button = Button.new()
	_hit_button.name = "HitButton"
	_hit_button.text = ""
	_hit_button.flat = true
	_hit_button.disabled = disabled
	_hit_button.focus_mode = Control.FOCUS_ALL
	_hit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_hit_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_hit_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_hit_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_hit_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	add_child(_hit_button)
	
	_hit_button.mouse_entered.connect(func() -> void:
		_is_hover = true
		_update_glass_state()
	)
	_hit_button.mouse_exited.connect(func() -> void:
		_is_hover = false
		if not is_selected:
			_is_pressed = false
		_update_glass_state()
	)
	_hit_button.button_down.connect(func() -> void:
		_is_pressed = true
		_update_glass_state()
	)
	_hit_button.button_up.connect(func() -> void:
		if is_selected:
			return
		_is_pressed = false
		_update_glass_state()
	)
	_hit_button.pressed.connect(func() -> void:
		pressed.emit()
	)
	
	move_child(_glass_bg, 0)
	move_child(_hit_button, 1)

func _rebuild_content() -> void:
	if _label != null:
		_label.queue_free()
		_label = null
	if _icon_rect != null:
		_icon_rect.queue_free()
		_icon_rect = null
	
	if content_type == ContentType.TEXT:
		_label = Label.new()
		_label.name = "Label"
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.text = text
		_label.add_theme_font_size_override("font_size", font_size)
		_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
		add_child(_label)
		move_child(_label, 1)
	else:
		_icon_rect = TextureRect.new()
		_icon_rect.name = "IconRect"
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.texture = icon
		add_child(_icon_rect)
		move_child(_icon_rect, 1)
		_update_icon_size()
	
	_update_layout()

func _update_icon_size() -> void:
	if _icon_rect == null or size.x <= 0 or size.y <= 0:
		return
	var icon_size := Vector2(size.x * icon_scale, size.y * icon_scale)
	_icon_rect.custom_minimum_size = icon_size
	_icon_rect.size = icon_size
	_icon_rect.position = (size - icon_size) / 2.0

func _on_resized() -> void:
	_update_layout()
	_update_glass_state()
	_update_icon_size()

func _update_layout() -> void:
	if _glass_bg == null:
		return
	
	var s := size
	if s.x <= 0 or s.y <= 0:
		s = custom_minimum_size
	
	_glass_bg.position = Vector2.ZERO
	_glass_bg.size = s
	
	if _label != null:
		_label.position = Vector2.ZERO
		_label.size = s
	
	if _icon_rect != null:
		_update_icon_size()
	
	if _hit_button != null:
		_hit_button.position = Vector2.ZERO
		_hit_button.size = s

func _get_mat() -> ShaderMaterial:
	if _glass_bg == null:
		return null
	return _glass_bg.material as ShaderMaterial

func _update_glass_state() -> void:
	var mat := _get_mat()
	if mat == null:
		return
	
	var s := size
	if s.x <= 0 or s.y <= 0:
		s = custom_minimum_size
		if s.x <= 0:
			s.x = 48
		if s.y <= 0:
			s.y = 48
	
	mat.set_shader_parameter("rect_size_px", s)
	mat.set_shader_parameter("corner_radius_px", corner_radius_px)
	mat.set_shader_parameter("border_color", Color(1.353, 1.353, 1.353, 0.18))
	mat.set_shader_parameter("blur_lod_center", 4.0)
	mat.set_shader_parameter("blur_lod_edge", 4.75)
	mat.set_shader_parameter("dispersion_strength", 1.4)
	mat.set_shader_parameter("rim_width_px", 0)
	
	var tint: Color
	var border_w: float
	
	if disabled:
		tint = Color(0.172, 0.172, 0.172, 0.85)
		border_w = 0
	elif _is_pressed:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.264, 0.556, 0.827, 0.8)
			ButtonType.THIRD:
				tint = Color(0.633, 0.429, 0.463, 0.8)
			ButtonType.PRIMARY:
				tint = Color(0.463, 0.729, 0.5, 0.8)
		border_w = 1.0
	elif _is_hover:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.499, 0.818, 1.162, 0.55)
			ButtonType.THIRD:
				tint = Color(0.854, 0.729, 0.812, 0.55)
			ButtonType.PRIMARY:
				tint = Color(0.729, 0.854, 0.749, 0.55)
		border_w = 0.5
	else:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.736, 0.781, 0.812, 0.716)
			ButtonType.THIRD:
				tint = Color(0.779, 0.779, 0.802, 0.722)
			ButtonType.PRIMARY:
				tint = Color(0.729, 0.779, 0.729, 0.722)
		border_w = 0
	
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("opacity", 1.0)
	mat.set_shader_parameter("border_width_px", border_w)
