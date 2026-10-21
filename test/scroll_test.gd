extends Control


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("滚轮向上滚动")
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("滚轮向下滚动")
