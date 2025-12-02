extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	self.disabled=false
	var return_shortcut = Shortcut.new()
	return_shortcut.events = [InputEventKey.new()]
	return_shortcut.events[0].keycode = KEY_ESCAPE
	
	self.shortcut = return_shortcut
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	pass
func _on_pressed() -> void:
	print("已点击返回")
	var parent = get_parent()
	
	await get_tree().create_timer(0.5).timeout
	if parent.modulate.a==0.0:
		parent.hide()
	pass # Replace with function body.
