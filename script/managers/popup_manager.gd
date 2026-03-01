extends Node

signal popup_button_pressed(metadata: String)
signal popup_opened
signal popup_closed

var _current_popup: GlobalPopup = null
var _popup_scene: PackedScene = load("res://component/GlassComponent/global_popup.tscn")

var _loading_active := false
var _loading_snapshot: Dictionary = {}

func show_popup(config: Dictionary) -> void:
	if _current_popup != null:
		var clear_on_new: bool = config.get("clear_on_new", true)
		if clear_on_new:
			_current_popup.queue_free()
		else:
			return
	
	_current_popup = _popup_scene.instantiate()
	var popup := _current_popup
	get_tree().root.add_child(_current_popup)
	
	_current_popup.setup(config)
	_current_popup.button_pressed.connect(func(metadata: String) -> void:
		_on_popup_button_pressed(popup, metadata)
	)
	_current_popup.closed.connect(func() -> void:
		_on_popup_closed(popup)
	)
	_current_popup.open()
	popup_opened.emit()


func _on_popup_button_pressed(popup: GlobalPopup, metadata: String) -> void:
	if popup != _current_popup:
		return
	popup_button_pressed.emit(metadata)


func _on_popup_closed(popup: GlobalPopup) -> void:
	if popup != _current_popup:
		return
	popup_closed.emit()
	_current_popup = null

func close_popup() -> void:
	if _current_popup != null:
		_current_popup.close()

func is_popup_open() -> bool:
	return _current_popup != null and is_instance_valid(_current_popup)

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
	
	show_popup(config)
	var popup := _current_popup
	if popup == null or not is_instance_valid(popup):
		return
	if not on_ok.is_valid() and not on_cancel.is_valid():
		return
	
	var wrapper: Callable
	wrapper = func(m: String) -> void:
		if not is_instance_valid(popup):
			return
		if popup.button_pressed.is_connected(wrapper):
			popup.button_pressed.disconnect(wrapper)
		if m == "confirm" and on_ok.is_valid():
			on_ok.call()
		elif m == "cancel" and on_cancel.is_valid():
			on_cancel.call()
	popup.button_pressed.connect(wrapper)

func show_alert(title: String, content: String, on_ok: Callable = Callable()) -> void:
	var config := {
		"size": "medium",
		"title": title,
		"content": content,
		"buttons": [
			{"text": "确定", "type": "primary", "metadata": "ok"}
		]
	}
	
	show_popup(config)
	var popup := _current_popup
	if popup == null or not is_instance_valid(popup):
		return
	if not on_ok.is_valid():
		return
	
	var wrapper: Callable
	wrapper = func(m: String) -> void:
		if not is_instance_valid(popup):
			return
		if popup.button_pressed.is_connected(wrapper):
			popup.button_pressed.disconnect(wrapper)
		if m == "ok":
			on_ok.call()
	popup.button_pressed.connect(wrapper)

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
		var popup := _current_popup
		popup.close()
		await popup.closed
	
	show_popup(config)

func has_open_popup() -> bool:
	return _current_popup != null and is_instance_valid(_current_popup)


func show_loading(title: String = "请稍候", label_text: String = "请稍候...", use_fade: bool = true) -> void:
	if has_open_popup():
		_loading_active = true
		_loading_snapshot = _current_popup.get_state_snapshot()
		if use_fade:
			await _current_popup.apply_loading_state_with_fade("请稍候...", label_text)
		else:
			_current_popup.apply_loading_state("请稍候...", label_text)
		return
	
	_loading_active = true
	_loading_snapshot = {}
	show_popup({
		"size": "medium",
		"title": title,
		"content_type": "label",
		"content": label_text,
		"buttons": [
			{
				"text": "请稍候...",
				"type": "secondary",
				"metadata": "_loading",
				"stay_open": true,
				"disabled": true,
			}
		]
	})


func hide_loading(restore_config: Dictionary = {}, use_fade: bool = true) -> void:
	if not has_open_popup():
		_loading_active = false
		_loading_snapshot = {}
		return
	
	var cfg: Dictionary = {}
	if not restore_config.is_empty():
		cfg = restore_config
		if not cfg.has("transition_animation"):
			cfg["transition_animation"] = use_fade
		update_popup(cfg)
	elif not _loading_snapshot.is_empty():
		cfg = _loading_snapshot
		if not cfg.has("transition_animation"):
			cfg["transition_animation"] = use_fade
		update_popup(cfg)
	
	_loading_active = false
	_loading_snapshot = {}
