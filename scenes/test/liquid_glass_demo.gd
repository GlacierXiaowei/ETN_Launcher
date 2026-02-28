extends Control

# Demo scene for tuning the liquid-glass UI shader.
# - Background texture can be set in the editor on the `Background` node.
# - The glass effect is applied to a single panel behind the content (Approach A).

@onready var background: TextureRect = $Background
@onready var glass_panel: ColorRect = $Main/DemoArea/Center/Card/GlassPanel
@onready var primary_button: Button = $Main/DemoArea/Center/Card/Content/Margin/VBox/ButtonRow/PrimaryButton
@onready var secondary_button: Button = $Main/DemoArea/Center/Card/Content/Margin/VBox/ButtonRow/SecondaryButton

@onready var controls_grid: GridContainer = $Main/ControlsPanel/Panel/Margin/VBox/Scroll/Grid

var _param_to_slider: Dictionary = {}
var _param_to_value_label: Dictionary = {}
var _is_syncing_ui := false


func _ready() -> void:
	# Give the demo usable typography/button styling without relying on a pre-authored Theme resource.
	ETNThemeFactory.apply_glass_theme(self)

	# Visually separate primary/secondary buttons in the demo.
	primary_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	secondary_button.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1))

	_ensure_glass_material()
	_apply_default_glass_params(_get_glass_material())
	_sync_rect_size_to_shader()
	glass_panel.resized.connect(_sync_rect_size_to_shader)

	_index_controls()
	_sync_sliders_from_material()


func _ensure_glass_material() -> void:
	var mat := glass_panel.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
		glass_panel.material = mat
		return

	if mat.shader == null:
		mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")


func _get_glass_material() -> ShaderMaterial:
	return glass_panel.material as ShaderMaterial


func _apply_default_glass_params(mat: ShaderMaterial) -> void:
	if mat == null:
		return

	# Defaults tuned for this demo; you can override via sliders or the Inspector.
	mat.set_shader_parameter("corner_radius_px", 22.0)
	mat.set_shader_parameter("opacity", 0.16)
	mat.set_shader_parameter("tint", Color(0.80, 0.90, 1.00, 0.35))
	mat.set_shader_parameter("refraction_strength_px", 9.0)
	mat.set_shader_parameter("edge_refraction_boost", 1.15)
	mat.set_shader_parameter("edge_falloff_px", 72.0)
	mat.set_shader_parameter("blur_lod_center", 0.0)
	mat.set_shader_parameter("blur_lod_edge", 3.2)
	mat.set_shader_parameter("dispersion_strength", 0.0)
	mat.set_shader_parameter("dispersion_px", 1.2)
	mat.set_shader_parameter("border_width_px", 1.0)
	mat.set_shader_parameter("border_color", Color(1, 1, 1, 0.16))
	mat.set_shader_parameter("rim_width_px", 14.0)
	mat.set_shader_parameter("rim_intensity", 1.0)
	mat.set_shader_parameter("rim_color", Color(1, 1, 1, 0.45))


func _sync_rect_size_to_shader() -> void:
	var mat := _get_glass_material()
	if mat == null:
		return
	mat.set_shader_parameter("rect_size_px", glass_panel.size)


func _index_controls() -> void:
	_param_to_slider.clear()
	_param_to_value_label.clear()

	if controls_grid == null:
		push_error("[LiquidGlassDemo] Controls grid not found; check scene node paths.")
		return

	for child in controls_grid.get_children():
		var slider := child as HSlider
		if slider == null:
			continue
		slider.custom_minimum_size = Vector2(240, 0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not slider.has_meta("param"):
			continue

		var param := str(slider.get_meta("param"))
		_param_to_slider[param] = slider

		# We lay out children as repeating triplets: Label, Slider, ValueLabel.
		var idx := slider.get_index()
		var value_label := controls_grid.get_child(idx + 1) as Label
		if value_label != null:
			_param_to_value_label[param] = value_label

		slider.value_changed.connect(func(v: float) -> void:
			_on_param_slider_changed(param, v)
		)


func _sync_sliders_from_material() -> void:
	var mat := _get_glass_material()
	if mat == null:
		return

	_is_syncing_ui = true
	for param in _param_to_slider.keys():
		var slider: HSlider = _param_to_slider[param]
		var v = mat.get_shader_parameter(param)
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			slider.value = float(v)
			_update_value_label(param, slider.value)
	_is_syncing_ui = false


func _on_param_slider_changed(param: String, value: float) -> void:
	if _is_syncing_ui:
		_update_value_label(param, value)
		return

	var mat := _get_glass_material()
	if mat == null:
		return

	mat.set_shader_parameter(param, value)
	_update_value_label(param, value)


func _update_value_label(param: String, value: float) -> void:
	var label: Label = _param_to_value_label.get(param, null)
	if label == null:
		return

	var text := "%.2f" % value
	if abs(value - round(value)) < 0.0001:
		text = "%d" % int(round(value))
	label.text = text


func _on_reset_pressed() -> void:
	_apply_default_glass_params(_get_glass_material())
	_sync_rect_size_to_shader()
	_sync_sliders_from_material()
