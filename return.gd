extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	var return_shortcut = Shortcut.new()
	return_shortcut.events = [InputEventKey.new()]
	return_shortcut.events[0].keycode = KEY_ESCAPE
	
	self.shortcut = return_shortcut

	# 连接按钮点击信号
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	pass
#注意 这里没有单独设置场景 而是 继承到ui 中 所以 ready 只会运行一次 注意！！！

#func _on_pressed() -> void:
	#遮罩似乎 不用 因为 这个好像有打断动画 

	#var parent=get_parent()
	
	#var tween_master_menu_in = $"../..".create_tween()
	#tween_master_menu_in.tween_property($"../../master_menu","modulate:a",1.0,0.5)
	#var this_menu_out = $"../..".create_tween()
	#this_menu_out.tween_property(parent,"self_modulate:a",0.0,0.5)
	#var menu_root = $"../.."
	#var tween = menu_root.create_tween()
	#tween.parallel().tween_property(menu_root.get_node("master_menu"), "modulate:a", 1.0, 0.5)
	#tween.parallel().tween_property(menu_root, "self_modulate:a", 0.0, 0.5)


	

	

	
 # Replace with function body.


func _on_return_pressed() -> void:
	var parent = get_parent()
	await get_tree().create_timer(0.5).timeout
	parent.hide()
	
	pass # Replace with function body.
