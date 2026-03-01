extends ColorRect
class_name GlassPanel

@export_group("Size Settings")
@export var medium_size: Vector2 = Vector2(600,400)
@export var large_size: Vector2 = Vector2(800,600)

enum SizeVariant { MEDIUM, LARGE }
@export var size_variant: SizeVariant = SizeVariant.MEDIUM:
	set(v):
		size_variant = v
		_apply_size_variant()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1,1,1,1)
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
			push_error("[GlassPanel] Failed to load shader")
		material = mat

func _on_resized() -> void:
	if material == null:
		return
	var mat = material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("rect_size_px", size)
