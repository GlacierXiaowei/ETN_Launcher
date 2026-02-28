extends Control
class_name GlassButton

signal pressed

enum ButtonType { PRIMARY, SECONDARY }
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

@export_group("Glass Effect - Border")
@export var border_width_normal: float =0
@export var border_width_hover: float =0.5
@export var border_width_pressed: float =1
@export var border_width_disabled: float =0

@export_group("Glass Effect - Tint Colors")
@export var normal_tint: Color = Color(0.92,0.92,0.96,0.50)
@export var hover_tint: Color = Color(0.96,0.96,1.0,0.60)
@export var pressed_tint: Color = Color(0.78,0.80,0.85,0.70)
@export var disabled_tint: Color = Color(0.172, 0.172, 0.172, 0.85)

@export_group("Corner")
@export var corner_radius_px: float =18.0

@export_group("Debug")
@export var debug_log: bool = false

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
			push_error("[GlassButton] Failed to load shader: res://assets/shaders/liquid_glass_ui.gdshader")
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
	match button_type:
		ButtonType.PRIMARY:
			normal_tint = Color(0.638, 0.696, 0.735, 0.716)
			hover_tint = Color(0.499, 0.818, 1.162, 0.55)
			pressed_tint = Color(0.264, 0.556, 0.827, 0.8)
		ButtonType.SECONDARY:
			normal_tint = Color(0.644, 0.644, 0.675, 0.722)
			hover_tint = Color(0.854, 0.729, 0.812, 0.55)
			pressed_tint = Color(0.633, 0.429, 0.463, 0.8)

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
		if debug_log:
			push_warning("[GlassButton] No ShaderMaterial on GlassBackground")
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
	
	mat.set_shader_parameter("border_color", Color(1.353, 1.353, 1.353, 0.18))
	#mat.set_shader_parameter("rim_width_px",6.0)
	#mat.set_shader_parameter("rim_intensity",4.0)
	#mat.set_shader_parameter("rim_color", Color(3.294,3.294,3.294,0.55))
	#mat.set_shader_parameter("refraction_strength_px",14.0)
	#mat.set_shader_parameter("edge_refraction_boost",4.0)
	#mat.set_shader_parameter("edge_falloff_px",28.0)
	
	mat.set_shader_parameter("blur_lod_center",4.5)
	mat.set_shader_parameter("blur_lod_edge",5.0)
	mat.set_shader_parameter("dispersion_strength",1.4)
	mat.set_shader_parameter("rim_width_px",0)
	##调不来这个参数
	#mat.set_shader_parameter("distortion_k1",-0.15)
	#mat.set_shader_parameter("distortion_k2",-0.5)
	

	if debug_log:
		push_warning("[GlassButton] update state size=%s hover=%s pressed=%s disabled=%s" % [str(s), str(_is_hover), str(_is_pressed), str(disabled)])

	if disabled:
		_apply_glass_params(disabled_tint,0.95, border_width_disabled)
		return

	if _is_pressed:
		_apply_glass_params(pressed_tint,1.0, border_width_pressed)
		return

	if _is_hover:
		_apply_glass_params(hover_tint,1.0, border_width_hover)
		return

	_apply_glass_params(normal_tint,1.0, border_width_normal)


func _apply_glass_params(t: Color, opa: float, border_w: float) -> void:
	var mat := _get_mat()
	if mat == null:
		return
	mat.set_shader_parameter("tint", t)
	mat.set_shader_parameter("opacity", opa)
	mat.set_shader_parameter("border_width_px", border_w)
