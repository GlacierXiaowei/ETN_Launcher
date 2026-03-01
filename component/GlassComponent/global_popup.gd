extends CanvasLayer
class_name GlobalPopup

signal popup_closed(metadata: String)
signal popup_opened

@onready var glass_panel: ColorRect = $PopupContainer/GlassPanel
@onready var title_label: Label = $PopupContainer/GlassPanel/Margin/VBox/Title
@onready var content_label: RichTextLabel = $PopupContainer/GlassPanel/Margin/VBox/Content
@onready var spacer: Control = $PopupContainer/GlassPanel/Margin/VBox/Spacer
@onready var button_container: HBoxContainer = $PopupContainer/GlassPanel/Margin/VBox/ButtonContainer

var _config: Dictionary = {}
var _buttons: Array[GlassButton] = []
var _is_opening := false

func setup(config: Dictionary) -> void:
	_config = config
	
	var size := "medium"
	if config.has("size"):
		size = config["size"]
	
	match size:
		"large":
			glass_panel.custom_minimum_size = Vector2(1000, 800)
		_:
			glass_panel.custom_minimum_size = Vector2(600, 400)
	
	spacer.custom_minimum_size.y = 48
	
	var content_min_y: float = 120.0
	if size == "large":
		content_min_y = 520.0
	content_label.custom_minimum_size.y = content_min_y
	
	# 设置 pivot_offset 为尺寸的一半（居中展开）
	await get_tree().process_frame
	glass_panel.pivot_offset = glass_panel.custom_minimum_size / 2.0
	
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
	
	for btn_config in buttons:
		var btn := GlassButton.new()
		btn.text = btn_config.get("text", "Button")
		
		var btn_type: String = btn_config.get("type", "secondary")
		if btn_type == "primary":
			btn.button_type = GlassButton.ButtonType.PRIMARY
		else:
			btn.button_type = GlassButton.ButtonType.SECONDARY
		
		var size_variant: GlassButton.SizeVariant = GlassButton.SizeVariant.MEDIUM
		if glass_panel.custom_minimum_size.x >= 800:
			size_variant = GlassButton.SizeVariant.LARGE
		btn.size_variant = size_variant
		
		var btn_metadata: String = btn_config.get("metadata", "")
		btn.pressed.connect(func() -> void:
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
	
	# 全部使用右对齐
	button_container.alignment = BoxContainer.ALIGNMENT_END

func _on_button_pressed(metadata: String) -> void:
	close(metadata)

func open() -> void:
	visible = true
	_is_opening = true
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	glass_panel.scale = Vector2(0.8, 0.8)
	glass_panel.modulate.a = 0.0
	
	tween.tween_property(glass_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glass_panel, "modulate:a", 1.0, 0.25)
	
	await tween.finished
	_is_opening = false
	popup_opened.emit()

func close(metadata: String = "") -> void:
	if _is_opening:
		await get_tree().create_timer(0.1).timeout
	
	var tween := create_tween()
	tween.tween_property(glass_panel, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	popup_closed.emit(metadata)
	queue_free()
