extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)

func _on_return_pressed() -> void:
	# 返回主测试场景
	SceneManager.switch_scene_with_loading("res://scenes/test/loading_test_scene.tscn", SceneManager.LOADING_MODE_FULL)
