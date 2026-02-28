extends ColorRect
class_name GlassPanel

@export_group("Glass Effect")
@export var corner_radius_px: float = 22.0:
	set(v):
		corner_radius_px = v
		_update_shader_param("corner_radius_px", v)

@export var opacity: float = 1.0:
	set(v):
		opacity = v
		_update_shader_param("opacity", v)

@export var tint: Color = Color(0.80, 0.90, 1.00, 0.35):
	set(v):
		tint = v
		_update_shader_param("tint", v)

@export var border_width_px: float = 1.5:
	set(v):
		border_width_px = v
		_update_shader_param("border_width_px", v)

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.18):
	set(v):
		border_color = v
		_update_shader_param("border_color", v)

@export var rim_width_px: float = 14.0:
	set(v):
		rim_width_px = v
		_update_shader_param("rim_width_px", v)

@export var rim_intensity: float = 1.0:
	set(v):
		rim_intensity = v
		_update_shader_param("rim_intensity", v)

@export var rim_color: Color = Color(1.0, 1.0, 1.0, 0.45):
	set(v):
		rim_color = v
		_update_shader_param("rim_color", v)

@export_group("Size Settings")
@export var medium_size: Vector2 = Vector2(600, 400)
@export var large_size: Vector2 = Vector2(800, 600)

enum SizeVariant { MEDIUM, LARGE }
@export var size_variant: SizeVariant = SizeVariant.MEDIUM:
	set(v):
		size_variant = v
		_apply_size_variant()

var _shader_loaded := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)
	_apply_size_variant()
	_init_shader()
	resized.connect(_on_resized)
	await get_tree().process_frame
	_on_resized()

func _apply_size_variant() -> void:
	match size_variant:
		SizeVariant.MEDIUM:
			custom_minimum_size = medium_size
		SizeVariant.LARGE:
			custom_minimum_size = large_size

func _init_shader() -> void:
	if material == null:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
		if mat.shader == null:
			push_error("[GlassPanel] Failed to load shader: res://assets/shaders/liquid_glass_ui.gdshader")
		material = mat
	
	_apply_all_params()

func _on_resized() -> void:
	_update_shader_param("rect_size_px", size)

func _update_shader_param(param_name: String, value) -> void:
	if material == null:
		return
	var mat = material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter(param_name, value)

func _apply_all_params() -> void:
	_update_shader_param("rect_size_px", size)
	#_update_shader_param("corner_radius_px", corner_radius_px)
	#_update_shader_param("opacity", opacity)
	#_update_shader_param("tint", tint)
	#_update_shader_param("border_width_px", border_width_px)
	#_update_shader_param("border_color", border_color)
	#_update_shader_param("rim_width_px", rim_width_px)
	#_update_shader_param("rim_intensity", rim_intensity)
	#_update_shader_param("rim_color", rim_color)
	#_update_shader_param("refraction_strength_px", 14.0)
	#_update_shader_param("edge_refraction_boost", 4.0)
	#_update_shader_param("edge_falloff_px", 28.0)
	#_update_shader_param("blur_lod_center", 3.0)
	#_update_shader_param("blur_lod_edge", 4.2)
	#_update_shader_param("dispersion_strength", 0.0)
