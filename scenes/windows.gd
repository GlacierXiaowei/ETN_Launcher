extends PanelContainer

var current_menu_tween: Tween
#设计一个信号 传出按下的按钮的内容
signal complete(button_text: String)

@onready var alarm_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/alarm
@onready var button_container: HBoxContainer = $MarginContainer/MarginContainer2/VBoxContainer/HBoxContainer
@onready var detail: RichTextLabel =$MarginContainer/MarginContainer2/VBoxContainer/detail

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MarginContainer/zhe_zhao_small_menu.grab_focus()
	$".".modulate.a=0.0
	ani_central("in")
	
	
func ani_central(type:String)->void:
	#淡入淡出
	if type=="in" :
		if is_instance_valid(current_menu_tween):
			current_menu_tween.kill()
		current_menu_tween = get_tree().create_tween()
		current_menu_tween.tween_property($".","modulate:a",1.0,0.4)	
	else:
		if is_instance_valid(current_menu_tween):
			current_menu_tween.kill()
		current_menu_tween = get_tree().create_tween()
		current_menu_tween.tween_property($".","modulate:a",0.0,0.4)	
		pass
	

	
func show_dialog(alarm_texts: String,detail_texts: String, button_texts: Array[String])-> void:
	alarm_label.text=alarm_texts
	detail.text=detail_texts
	$MarginContainer/MarginContainer2/VBoxContainer/detail.bbcode_enabled=true
	#首先要 关掉之前我们生成的按钮 不然可能会冲突
	for child in $MarginContainer/MarginContainer2/VBoxContainer/HBoxContainer.get_children():
		child.queue_free()
	
# 2. 第二步：创建我们的“弹簧”模板
	# Control.new() 创建一个空白的UI节点
	# .size_flags_horizontal = Control.SIZE_EXPAND_FILL 让它在水平方向上尽可能地伸展
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 3. 第三步：根据按钮数量，巧妙地添加按钮和弹簧
	
	# 如果只有一个按钮，为了居中，在它前后都放一个弹簧
	if button_texts.size() == 1:
		button_container.add_child(spacer.duplicate()) # 添加左侧弹簧
		_create_and_add_button(button_texts[0])      # 添加按钮
		button_container.add_child(spacer.duplicate()) # 添加右侧弹簧
	else:
		# 对于多个按钮的情况
		for i in range(button_texts.size()):
			# 添加按钮
			_create_and_add_button(button_texts[i])
			
			# 只要不是最后一个按钮，就在它后面加一个弹簧
			if i < button_texts.size() - 1:
				button_container.add_child(spacer.duplicate())
	# ==================== 修改结束 ====================
# 为了让代码更清晰，我把创建按钮的逻辑提取成一个辅助函数
func _create_and_add_button(text: String) -> void:
	var button = Button.new()
	button.text = text
	if text=="取消" or text=="取消":
		var return_shortcut = Shortcut.new()
		return_shortcut.events = [InputEventKey.new()]
		return_shortcut.events[0].keycode = KEY_ESCAPE
	# 当按钮被点击时，发出 complete 信号，并把按钮的文字传递出去
	# 这是为了让 await windows.complete 能接收到结果
	button.pressed.connect(_on_self_pressed.bind(text)) # 点击后销毁窗口)
	button_container.add_child(button)	
func _on_self_pressed(text:String) ->void:
	
	ani_central("out")
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		complete.emit(text)
		self.queue_free()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
