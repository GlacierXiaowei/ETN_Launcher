extends Control

@onready var btn_medium: Button = $VBox/HBoxMedium/ButtonMedium
@onready var btn_large: Button = $VBox/HBoxLarge/ButtonLarge
@onready var status_label: Label = $VBox/StatusLabel

var _test_results: Array[String] = []

func _ready() -> void:
	btn_medium.pressed.connect(_on_medium_pressed)
	btn_large.pressed.connect(_on_large_pressed)
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("测试场景已就绪")

func _on_medium_pressed() -> void:
	_add_status("点击: 打开中等弹窗")
	var config := {
		"size": "medium",
		"title": "中等弹窗测试",
		"content": "这是一个中等大小的弹窗，用于测试Phase1功能。",
		"buttons": [
			{"text": "确定", "type": "primary", "metadata": "medium_ok"}
		]
	}
	PopupManager.show_popup(config)

func _on_large_pressed() -> void:
	_add_status("点击: 打开大弹窗")
	var config := {
		"size": "large",
		"title": "大弹窗测试",
		"content": "[b]这是大弹窗测试[/b]\n\n用于显示更新公告等长内容。\n\n• 测试内容1\n• 测试内容2\n• 测试内容3",
		"content_type": "richtext",
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "large_close"}
		]
	}
	PopupManager.show_popup(config)

func _on_popup_button_pressed(metadata: String) -> void:
	_add_status("收到回调: metadata=" + metadata)
	_verify_callback(metadata)

func _verify_callback(metadata: String) -> void:
	var expected := ["medium_ok", "large_close"]
	if metadata in expected:
		_add_status("✓ 回调验证通过: " + metadata)
	else:
		_add_status("✗ 回调验证失败: " + metadata)

func _add_status(msg: String) -> void:
	status_label.text = msg
	_test_results.append(msg)
	print("[TestPopup] " + msg)
