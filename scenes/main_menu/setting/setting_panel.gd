extends Control

@onready var zhe_zhao: ColorRect = $ZheZhao

signal enter_outer_setting
signal exit_outer_setting

func _on_button_pressed() -> void:
	var title : String = "敬请期待"
	var content : String = "预计3.2.0.0版本之前完善"
	
	PopupManager.show_popup({"title" :title , "content" :content })


func _on_back_pressed() -> void:
	exit_outer_setting.emit()


func _on_exit_outer_setting() -> void:
	await get_tree().create_timer(0.5).timeout
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_enter_outer_setting() -> void:
	await get_tree().create_timer(0.5).timeout
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE
