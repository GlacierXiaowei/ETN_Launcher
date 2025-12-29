extends PanelContainer

signal complete(button_text: String)

# --- 节点引用 
@onready var alarm_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/alarm
@onready var button_container: HBoxContainer = $MarginContainer/MarginContainer2/VBoxContainer/HBoxContainer
@onready var detail: RichTextLabel = $MarginContainer/MarginContainer2/VBoxContainer/detail

# --- 新增的节点引用 (根据你的场景树) ---
@onready var progress_bar: ProgressBar = $MarginContainer/MarginContainer2/VBoxContainer/ProgressBar

var current_menu_tween: Tween

func _ready() -> void:
	# --- 你原有的逻辑 ---
	$MarginContainer/zhe_zhao_small_menu.grab_focus()
	$".".modulate.a = 0.0
	ani_central("in")
	# --- 新增：确保启动时进度条是隐藏的 ---
	progress_bar.hide()

# 新函数：更新进度条和文本。由 WindowsManager 调用。
func update_progress(progress_percentage: float, text: String):
	if not progress_bar.visible:
		progress_bar.show() # 如果是第一次更新，就让它显示出来
	
	progress_bar.value = progress_percentage
	# 用 detail 区域显示进度文本，如 "正在下载... 5.5MB / 10.2MB"
	# 允许 BBCode，这样可以做一些高亮
	detail.bbcode_enabled = true 
	detail.text = text 

#以下函数准备删除 感觉很重复
# 新函数：切换到“忙碌”模式，只显示一个“取消”按钮。由 WindowsManager 调用。
func set_busy_mode(alarm_texts: String, detail_texts: String):
	alarm_label.text = alarm_texts
	detail.text = detail_texts
	ani_central("in")
	
	# 为了居中，在“取消”按钮两边添加弹簧
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(spacer.duplicate())
	_create_and_add_button("取消") # 只创建一个取消按钮
	button_container.add_child(spacer.duplicate())

# ======================================================================
# vvvvvvvvvvvvvvvv   你原有的函数 (完全保留并优化)   vvvvvvvvvvvvvvvvvvvv
# ======================================================================
# 你原有的 show_dialog 函数，完美保留
func show_dialog(alarm_texts: String, detail_texts: String, button_texts: Array[String]) -> void:
	alarm_label.text = alarm_texts
	detail.text = detail_texts
	detail.bbcode_enabled = true
	ani_central("in")

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if button_texts.size() == 1:
		button_container.add_child(spacer.duplicate())
		_create_and_add_button(button_texts[0])
		button_container.add_child(spacer.duplicate())
	else:
		for i in range(button_texts.size()):
			_create_and_add_button(button_texts[i])
			if i < button_texts.size() - 1:
				button_container.add_child(spacer.duplicate())

## 辅助函数：清空按钮 (避免重复)
#func _clear_buttons():
	#for child in button_container.get_children():
		#child.queue_free()

# 你原有的创建按钮函数，完美保留
func _create_and_add_button(text: String) -> void:
	var button = Button.new()
	button.text = text
	button.pressed.connect(_on_self_pressed.bind(text))
	button_container.add_child(button)
# 你原有的动画和销毁函数，完美保留
func _on_self_pressed(text: String) -> void:
	ani_central("out")
	await get_tree().create_timer(0.3).timeout
	if text=="请等待":
		complete.emit(text)
		return 
	if is_instance_valid(self):
		complete.emit(text)
		queue_free()

func ani_central(type: String) -> void:
	if is_instance_valid(current_menu_tween):
		current_menu_tween.kill()
	current_menu_tween = get_tree().create_tween()
	var target_alpha = 1.0 if type == "in" else 0.0
	current_menu_tween.tween_property($".", "modulate:a", target_alpha, 0.3)
