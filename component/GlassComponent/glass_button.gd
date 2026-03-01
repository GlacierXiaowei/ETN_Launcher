extends Control
class_name GlassButton

signal pressed

enum ButtonType { PRIMARY, SECONDARY, THIRD }
enum SizeVariant { MEDIUM, LARGE }

@export_group("Content")
@export var text: String = "Button":
	set(v):
		text = v
		if _label != null:
			_label.text = v

@export_group("State")
@export var disabled: bool = false:
	set(v):
		disabled = v
		if _hit_button != null:
			_hit_button.disabled = v
		_update_glass_state()

@export_group("Button Style")
@export var button_type: ButtonType = ButtonType.SECONDARY:
	set(v):
		button_type = v
		_apply_type_style()

@export var size_variant: SizeVariant = SizeVariant.MEDIUM:
	set(v):
		size_variant = v
		_apply_size()

@export_group("Glass Effect")
@export var corner_radius_px: float =18.0

var _glass_bg: ColorRect
var _label: Label
var _hit_button: Button
var _is_hover := false
var _is_pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false

	_apply_size()
	_build_nodes_if_needed()
	_apply_type_style()
	_update_layout()

	resized.connect(_on_resized)
	await get_tree().process_frame
	_update_layout()
	_update_glass_state()

func _build_nodes_if_needed() -> void:
	if _glass_bg == null:
		_glass_bg = ColorRect.new()
		_glass_bg.name = "GlassBackground"
		_glass_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glass_bg.color = Color(1,1,1,1)
		add_child(_glass_bg)

		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
		if mat.shader == null:
			push_error("[GlassButton] Failed to load shader")
		_glass_bg.material = mat

	if _label == null:
		_label = Label.new()
		_label.name = "Label"
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.text = text
		add_child(_label)

	if _hit_button == null:
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
			_is_pressed = false
			_update_glass_state()
		)
		_hit_button.button_down.connect(func() -> void:
			_is_pressed = true
			_update_glass_state()
		)
		_hit_button.button_up.connect(func() -> void:
			_is_pressed = false
			_update_glass_state()
		)
		_hit_button.pressed.connect(func() -> void:
			pressed.emit()
		)

	move_child(_glass_bg,0)
	move_child(_label,1)
	move_child(_hit_button,2)

func _apply_type_style() -> void:
	_update_glass_state()

func _apply_size() -> void:
	match size_variant:
		SizeVariant.MEDIUM:
			custom_minimum_size = Vector2(140,48)
		SizeVariant.LARGE:
			custom_minimum_size = Vector2(180,56)

func _on_resized() -> void:
	_update_layout()
	_update_glass_state()

func _update_layout() -> void:
	if _glass_bg == null:
		return

	var s := size
	if s.x <=0 or s.y <=0:
		s = custom_minimum_size

	_glass_bg.position = Vector2.ZERO
	_glass_bg.size = s

	_label.position = Vector2.ZERO
	_label.size = s

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

	var s := _glass_bg.size
	if s.x <=0 or s.y <=0:
		s = custom_minimum_size
		if s.x <=0:
			s.x =120
		if s.y <=0:
			s.y =40

	mat.set_shader_parameter("rect_size_px", s)
	mat.set_shader_parameter("corner_radius_px", corner_radius_px)
	mat.set_shader_parameter("border_color", Color(1.353,1.353,1.353,0.18))
	mat.set_shader_parameter("blur_lod_center",4.0)
	mat.set_shader_parameter("blur_lod_edge",4.75)
	mat.set_shader_parameter("dispersion_strength",1.4)
	mat.set_shader_parameter("rim_width_px",0)

	var tint: Color
	var border_w: float
	
	if disabled:
		tint = Color(0.172,0.172,0.172,0.85)
		border_w =0
	elif _is_pressed:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.264,0.556,0.827,0.8)
			ButtonType.THIRD:
				tint = Color(0.633,0.429,0.463,0.8)
			ButtonType.PRIMARY:
				tint = Color(0.463,0.729,0.5,0.8)
		border_w =1.0
	elif _is_hover:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.499,0.818,1.162,0.55)
			ButtonType.THIRD:
				tint = Color(0.854,0.729,0.812,0.55)
			ButtonType.PRIMARY:
				tint = Color(0.729,0.854,0.749,0.55)
		border_w =0.5
	else:
		match button_type:
			ButtonType.SECONDARY:
				tint = Color(0.736,0.781,0.812,0.716)
			ButtonType.THIRD:
				tint = Color(0.779,0.779,0.802,0.722)
			ButtonType.PRIMARY:
				tint = Color(0.729,0.779,0.729,0.722)
		border_w =0

	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("opacity",1.0)
	mat.set_shader_parameter("border_width_px", border_w)
