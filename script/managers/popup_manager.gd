extends Node

signal popup_button_pressed(metadata: String)
signal popup_opened
signal popup_closed

var _current_popup: GlobalPopup = null
var _popup_scene: PackedScene = load("res://component/GlassComponent/global_popup.tscn")

func show_popup(config: Dictionary) -> void:
	if _current_popup != null:
		var clear_on_new: bool = config.get("clear_on_new", true)
		if clear_on_new:
			_current_popup.queue_free()
		else:
			return
	
	_current_popup = _popup_scene.instantiate()
	get_tree().root.add_child(_current_popup)
	
	_current_popup.setup(config)
	_current_popup.popup_closed.connect(_on_popup_closed)
	_current_popup.open()
	popup_opened.emit()

func _on_popup_closed(metadata: String) -> void:
	popup_button_pressed.emit(metadata)
	popup_closed.emit()
	_current_popup = null

func close_popup() -> void:
	if _current_popup != null:
		_current_popup.close()

func is_popup_open() -> bool:
	return _current_popup != null

func show_confirm(title: String, content: String, on_ok: Callable, on_cancel: Callable = Callable()) -> void:
	var config := {
		"size": "medium",
		"title": title,
		"content": content,
		"buttons": [
			{"text": "取消", "type": "secondary", "metadata": "cancel"},
			{"text": "确定", "type": "primary", "metadata": "confirm"}
		]
	}
	
	var callback := func(m: String) -> void:
		if m == "confirm":
			on_ok.call()
		elif m == "cancel" and on_cancel.is_valid():
			on_cancel.call()
	
	if on_cancel.is_valid():
		popup_button_pressed.connect(callback)
	elif on_ok.is_valid():
		popup_button_pressed.connect(callback)
	
	show_popup(config)

func show_alert(title: String, content: String, on_ok: Callable = Callable()) -> void:
	var config := {
		"size": "medium",
		"title": title,
		"content": content,
		"buttons": [
			{"text": "确定", "type": "primary", "metadata": "ok"}
		]
	}
	
	if on_ok.is_valid():
		var callback := func(m: String) -> void:
			if m == "ok":
				on_ok.call()
		popup_button_pressed.connect(callback)
	
	show_popup(config)

func update_popup(config: Dictionary) -> bool:
	if _current_popup == null or not is_instance_valid(_current_popup):
		return false
	
	var use_fade := config.get("transition_animation", false) as bool
	if use_fade:
		_current_popup.update_with_fade(config)
	else:
		_current_popup.update(config)
	return true

func close_and_show_new(config: Dictionary) -> void:
	if _current_popup != null:
		_current_popup.close()
		await popup_closed
	
	show_popup(config)

func has_open_popup() -> bool:
	return _current_popup != null and is_instance_valid(_current_popup)
