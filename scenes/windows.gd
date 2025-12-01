extends PanelContainer

var current_menu_tween: Tween
#设计一个信号 传出按下的按钮的内容
signal complete(button_text: String)

@onready var alarm_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/alarm
@onready var button_container: HBoxContainer = $MarginContainer/MarginContainer2/VBoxContainer/HBoxContainer
@onready var detail: RichTextLabel =$MarginContainer/MarginContainer2/VBoxContainer/detail

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".modulate.a=0.0
	ani_central("in")
	
func ani_central(type:String)->void:
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
	
	#首先要 关掉之前我们生成的按钮 不然可能会冲突
	for child in $MarginContainer/MarginContainer2/VBoxContainer/HBoxContainer.get_children():
		child.queue_free()
	
	# 3. 遍历传入的按钮文本数组，动态创建按钮
	for text in button_texts:
		var button = Button.new()
		button.text = text
		# 连接按钮的 "pressed" 信号到我们自己的处理函数上
		# 使用 .bind(text) 是一个非常关键的技巧，它可以在连接信号时“绑定”额外参数
		# 这样，当按钮被按下时，我们就能知道是哪个按钮了
		button.pressed.connect(_on_self_pressed.bind(text))
		button_container.add_child(button)

	
	 # Replace with function body.
func _on_self_pressed(text:String) ->void:
	complete.emit(text)
	ani_central("out")
	await get_tree().create_timer(0.3)
	self.queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
