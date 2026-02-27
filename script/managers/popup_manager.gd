extends Node

var popup_scene: PackedScene = null
var current_popup: Control = null

func _ready() -> void:
	pass

@warning_ignore("unused_parameter")
func show_popup(config: Dictionary) -> void:
	pass

func close_popup() -> void:
	pass

func is_popup_open() -> bool:
	return current_popup != null
