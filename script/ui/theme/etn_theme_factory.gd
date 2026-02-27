extends RefCounted

class_name ETNThemeFactory

# 说明：
# - 本文件用于在运行时统一应用启动器UI主题，并创建"液态玻璃"卡片底板。
# - 由于不直接修改现有 .tscn 文件，本工厂函数返回可直接 add_child() 的节点。


static func apply_glass_theme(root: Control) -> void:
	# 优先加载资源主题；若资源不存在，则回退到运行时创建的简易主题。
	var theme: Theme = null
	if ResourceLoader.exists("res://assets/themes/etn_glass_dark.theme.tres"):
		theme = load("res://assets/themes/etn_glass_dark.theme.tres")
	else:
		theme = _build_fallback_theme()

	root.theme = theme


static func create_glass_card() -> ColorRect:
	var card := ColorRect.new()
	card.name = "GlassCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.color = Color(1, 1, 1, 1)
	card.clip_contents = false

	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
	card.material = mat

	# 默认参数（后续可在调用方按需覆盖）
	mat.set_shader_parameter("rect_size_px", Vector2(256, 256))
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

	return card


static func _build_fallback_theme() -> Theme:
	var theme := Theme.new()

	var font: Font = null
	if ResourceLoader.exists("res://assets/fonts/unifont-16.0.02.otf"):
		font = load("res://assets/fonts/unifont-16.0.02.otf")
		theme.default_font = font

	# Label
	theme.set_color("font_color", "Label", Color(0.92, 0.95, 0.98, 1.0))
	# RichTextLabel
	theme.set_color("default_color", "RichTextLabel", Color(0.78, 0.82, 0.86, 1.0))

	# Button - 简化版：主次按钮在脚本里通过 add_theme_*_override 做区分
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.18, 0.32, 0.85)
	sb_normal.corner_radius_top_left = 16
	sb_normal.corner_radius_top_right = 16
	sb_normal.corner_radius_bottom_left = 16
	sb_normal.corner_radius_bottom_right = 16
	sb_normal.content_margin_left = 18
	sb_normal.content_margin_right = 18
	sb_normal.content_margin_top = 12
	sb_normal.content_margin_bottom = 12

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.16, 0.24, 0.40, 0.92)

	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.10, 0.14, 0.26, 0.92)

	theme.set_stylebox("normal", "Button", sb_normal)
	theme.set_stylebox("hover", "Button", sb_hover)
	theme.set_stylebox("pressed", "Button", sb_pressed)
	theme.set_color("font_color", "Button", Color(0.95, 0.97, 1.0, 1.0))
	theme.set_color("font_disabled_color", "Button", Color(0.80, 0.84, 0.90, 0.55))

	return theme
