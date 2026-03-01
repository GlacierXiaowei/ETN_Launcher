extends CanvasLayer
class_name GlobalPopup

signal button_pressed(metadata: String)
signal closed
signal popup_opened

@onready var glass_panel: ColorRect = $PopupContainer/GlassPanel
@onready var title_label: Label = $PopupContainer/GlassPanel/Margin/VBox/Title
@onready var content_label: RichTextLabel = $PopupContainer/GlassPanel/Margin/VBox/Content
@onready var spacer: Control = $PopupContainer/GlassPanel/Margin/VBox/Spacer
@onready var button_container: HBoxContainer = $PopupContainer/GlassPanel/Margin/VBox/ButtonContainer
@onready var popup_container: Control = $PopupContainer

const DEFAULT_CORNER_RADIUS_PX := 24.0
const DIM_ALPHA := 0.5

const CLOSE_BLUR_PEAK := 4.0
const CLOSE_T_BLUR_IN := 0.15
const CLOSE_T_MAIN := 0.4

var _config: Dictionary = {}
var _buttons: Array[GlassButton] = []
var _is_opening := false
var _is_closing := false

var _dim_background: ColorRect = null
var _blur_overlay: ColorRect = null

func setup(config: Dictionary) -> void:
	_config = config
	if not _config.has("content_type"):
		_config["content_type"] = "richtext"
	if not _config.has("content"):
		_config["content"] = ""
	if not _config.has("title"):
		_config["title"] = ""
	if not _config.has("buttons"):
		_config["buttons"] = []
	
	_create_dim_background()
	_create_blur_overlay()
	
	var size := "medium"
	if config.has("size"):
		size = config["size"]
	
	match size:
		"large":
			glass_panel.custom_minimum_size = Vector2(1000, 800)
		_:
			glass_panel.custom_minimum_size = Vector2(600, 400)

	# Keep the popup centered by updating offsets (scene anchors are centered).
	# NOTE: Avoid setting `position` directly; it will break anchor-based centering.
	var target_size := glass_panel.custom_minimum_size
	_apply_glass_panel_centered_layout(target_size)
	
	spacer.custom_minimum_size.y = 48
	
	var content_min_y: float = 120.0
	if size == "large":
		content_min_y = 520.0
	content_label.custom_minimum_size.y = content_min_y
	
	# Ensure layout is applied before using size-dependent shader params.
	await get_tree().process_frame
	# Re-apply centering after first layout pass (prevents top-left placement).
	_apply_glass_panel_centered_layout(target_size)
	glass_panel.pivot_offset = glass_panel.size / 2.0
	_sync_glass_panel_shader_params()
	
	if config.has("title"):
		title_label.text = config["title"]
	
	if config.has("content"):
		var content_type := "richtext"
		if config.has("content_type"):
			content_type = config["content_type"]
		
		if content_type == "richtext":
			content_label.bbcode_enabled = true
			content_label.text = config["content"]
		else:
			content_label.bbcode_enabled = false
			content_label.text = config["content"]
	
	_build_buttons(config.get("buttons", []))
	
	glass_panel.resized.connect(_on_glass_panel_resized)
	_update_blur_overlay_size()


func _on_glass_panel_resized() -> void:
	_sync_glass_panel_shader_params()
	_update_blur_overlay_size()


func _apply_glass_panel_centered_layout(target_size: Vector2) -> void:
	glass_panel.anchor_left = 0.5
	glass_panel.anchor_top = 0.5
	glass_panel.anchor_right = 0.5
	glass_panel.anchor_bottom = 0.5
	glass_panel.offset_left = -target_size.x * 0.5
	glass_panel.offset_right = target_size.x * 0.5
	glass_panel.offset_top = -target_size.y * 0.5
	glass_panel.offset_bottom = target_size.y * 0.5


func _sync_glass_panel_shader_params() -> void:
	var mat := glass_panel.material as ShaderMaterial
	if mat == null:
		return
	# liquid_glass_ui.gdshader expects rect_size_px for correct rounded corners and distortion.
	mat.set_shader_parameter("rect_size_px", glass_panel.size)
	# Force a sane default corner radius to keep visuals consistent across sizes.
	# This also fixes "large" feeling like it has no rounded corners.
	mat.set_shader_parameter("corner_radius_px", DEFAULT_CORNER_RADIUS_PX)


func _get_glass_panel_corner_radius_px() -> float:
	var corner_px := DEFAULT_CORNER_RADIUS_PX
	var mat := glass_panel.material as ShaderMaterial
	if mat == null:
		return corner_px
	var v = mat.get_shader_parameter("corner_radius_px")
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		corner_px = float(v)
	return corner_px

func _build_buttons(buttons: Array) -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	
	if buttons.is_empty():
		var default_btn := {
			"text": "确定",
			"type": "primary",
			"metadata": "ok"
		}
		buttons = [default_btn]
	
	if _config == null:
		_config = {}
	_config["buttons"] = buttons
	
	# 按类型排序：primary -> secondary -> third（从左到右）
	var type_order := {"primary": 0, "secondary": 1, "third": 2}
	buttons.sort_custom(func(a, b):
		var order_a := type_order.get(a.get("type", "secondary"), 1) as int
		var order_b := type_order.get(b.get("type", "secondary"), 1) as int
		return order_a < order_b
	)
	
	for btn_config in buttons:
		var btn := GlassButton.new()
		btn.text = btn_config.get("text", "Button")
		btn.disabled = btn_config.get("disabled", false) as bool
		
		var btn_type := btn_config.get("type", "secondary") as String
		match btn_type:
			"primary":
				btn.button_type = GlassButton.ButtonType.PRIMARY
			"third":
				btn.button_type = GlassButton.ButtonType.THIRD
			_:
				btn.button_type = GlassButton.ButtonType.SECONDARY
		
		var size_variant: GlassButton.SizeVariant = GlassButton.SizeVariant.MEDIUM
		if glass_panel.custom_minimum_size.x >= 800:
			size_variant = GlassButton.SizeVariant.LARGE
		btn.size_variant = size_variant
		
		var btn_metadata := btn_config.get("metadata", "") as String
		var btn_stay_open := btn_config.get("stay_open", false) as bool
		btn.set_meta("stay_open", btn_stay_open)
		btn.pressed.connect(func() -> void:
			_last_pressed_btn = btn
			_on_button_pressed(btn_metadata)
		)
		
		button_container.add_child(btn)
		_buttons.append(btn)
		
		# 设置自定义尺寸（如果配置了）
		if btn_config.has("min_width") or btn_config.has("min_height"):
			var min_size := btn.custom_minimum_size
			if btn_config.has("min_width"):
				min_size.x = btn_config["min_width"]
			if btn_config.has("min_height"):
				min_size.y = btn_config["min_height"]
			btn.custom_minimum_size = min_size
	
	# 设置居中对齐
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	# 设置按钮间距
	button_container.add_theme_constant_override("separation", 36)

var _last_pressed_btn: GlassButton = null

func _on_button_pressed(metadata: String) -> void:
	var stay_open := false
	if _last_pressed_btn != null:
		stay_open = _last_pressed_btn.get_meta("stay_open", false) as bool
	button_pressed.emit(metadata)
	_last_pressed_btn = null
	if stay_open:
		return
	close()

func open() -> void:
	visible = true
	_is_opening = true
	_is_closing = false
	glass_panel.scale = Vector2(1.0, 1.0)
	
	if _dim_background != null:
		_dim_background.visible = true
		_dim_background.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	glass_panel.scale = Vector2(0.8, 0.8)
	glass_panel.modulate.a = 0.0
	
	tween.tween_property(glass_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(glass_panel, "modulate:a", 1.0, 0.25)
	
	if _dim_background != null:
		tween.tween_property(_dim_background, "modulate:a", DIM_ALPHA, 0.25)
	
	await tween.finished
	_is_opening = false
	popup_opened.emit()

func set_title(title: String) -> void:
	title_label.text = title

func set_content(text: String, type: String = "label") -> void:
	if type == "richtext":
		content_label.bbcode_enabled = true
		content_label.text = text
	else:
		content_label.bbcode_enabled = false
		content_label.text = text

func set_buttons(buttons: Array) -> void:
	_build_buttons(buttons)

func update(config: Dictionary) -> void:
	if _config == null:
		_config = {}
	for k in config.keys():
		_config[k] = config[k]
	
	if config.has("title"):
		set_title(config["title"])
	
	if config.has("content"):
		var content_type := config.get("content_type", "label") as String
		set_content(config["content"], content_type)
	
	if config.has("buttons"):
		set_buttons(config["buttons"])


func get_state_snapshot() -> Dictionary:
	# Snapshot only the state we can reliably restore via PopupManager.update_popup().
	var snap: Dictionary = {}
	snap["size"] = _config.get("size", "medium")
	snap["title"] = _config.get("title", "")
	snap["content_type"] = _config.get("content_type", "richtext")
	snap["content"] = _config.get("content", "")
	snap["buttons"] = _config.get("buttons", [])
	return snap


func apply_loading_state(wait_button_text: String = "请稍候...", label_text: String = "") -> void:
	var ct := _config.get("content_type", "richtext") as String
	if ct != "richtext":
		if label_text != "":
			set_content(label_text, "label")
	# Ensure the special loading button never triggers close() even if metadata is misrouted.
	set_buttons([
		{
			"text": wait_button_text,
			"type": "secondary",
			"metadata": "_loading",
			"stay_open": true,
			"disabled": true,
		}
	])


func apply_loading_state_with_fade(wait_button_text: String = "请稍候...", label_text: String = "") -> void:
	var content_container := $PopupContainer/GlassPanel/Margin/VBox
	var tween := create_tween()
	tween.tween_property(content_container, "modulate:a", 0.0, 0.15)
	await tween.finished
	apply_loading_state(wait_button_text, label_text)
	tween = create_tween()
	tween.tween_property(content_container, "modulate:a", 1.0, 0.15)

func update_with_fade(new_config: Dictionary) -> void:
	var content_container := $PopupContainer/GlassPanel/Margin/VBox
	
	var tween := create_tween()
	tween.tween_property(content_container, "modulate:a", 0.0, 0.15)
	await tween.finished
	
	update(new_config)
	
	tween = create_tween()
	tween.tween_property(content_container, "modulate:a", 1.0, 0.15)


func close() -> void:
	if _is_closing:
		return
	_is_closing = true
	if _is_opening:
		await get_tree().create_timer(0.1).timeout
	
	_do_blur_close_animation()


func _create_dim_background() -> void:
	if _dim_background != null:
		return
	
	_dim_background = ColorRect.new()
	_dim_background.name = "DimBackground"
	_dim_background.color = Color(0, 0, 0, DIM_ALPHA)
	_dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_background.visible = false
	add_child(_dim_background)
	move_child(_dim_background, 0)


func _create_blur_overlay() -> void:
	if _blur_overlay != null:
		return
	
	_blur_overlay = ColorRect.new()
	_blur_overlay.name = "BlurOverlay"
	_blur_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_blur_overlay.visible = false
	_blur_overlay.color = Color(1, 1, 1, 1)
	
	var blur_mat := ShaderMaterial.new()
	blur_mat.shader = load("res://assets/shaders/transition_blur.gdshader")
	blur_mat.set_shader_parameter("blur_amount", 0.0)
	blur_mat.set_shader_parameter("corner_radius_px", _get_glass_panel_corner_radius_px())
	blur_mat.set_shader_parameter("rect_size_px", glass_panel.size)
	_blur_overlay.material = blur_mat
	
	popup_container.add_child(_blur_overlay)
	popup_container.move_child(_blur_overlay, popup_container.get_child_count() - 1)


func _update_blur_overlay_size() -> void:
	if _blur_overlay == null:
		return
	_blur_overlay.size = glass_panel.size
	_blur_overlay.position = glass_panel.position
	var mat := _blur_overlay.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size_px", _blur_overlay.size)
		mat.set_shader_parameter("corner_radius_px", _get_glass_panel_corner_radius_px())


func _do_blur_close_animation() -> void:
	_update_blur_overlay_size()
	
	_blur_overlay.visible = true
	_blur_overlay.modulate.a = 1.0
	
	var blur_mat = _blur_overlay.material as ShaderMaterial

	# Close animation as the inverse of open:
	# - Blur in quickly, then blur out while fading/scaling down.
	# Total duration >= 0.4s.
	var t_blur_in := CLOSE_T_BLUR_IN
	var t_main := CLOSE_T_MAIN
	var blur_peak := CLOSE_BLUR_PEAK

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(blur_mat, "shader_parameter/blur_amount", blur_peak, t_blur_in)
	await tween.finished

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blur_mat, "shader_parameter/blur_amount", 0.0, t_main)
	tween.tween_property(glass_panel, "scale", Vector2(0.8, 0.8), t_main)
	tween.tween_property(glass_panel, "modulate:a", 0.0, t_main)
	tween.tween_property(_blur_overlay, "modulate:a", 0.0, t_main)
	if _dim_background != null:
		tween.tween_property(_dim_background, "modulate:a", 0.0, t_main)
	await tween.finished

	closed.emit()
	queue_free()
