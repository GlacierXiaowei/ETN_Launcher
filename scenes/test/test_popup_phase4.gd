extends Control

@onready var btn_test_close: Button = $VBox/HBoxTestClose/ButtonTestClose
@onready var btn_test_multi_buttons: Button = $VBox/HBoxMultiButtons/ButtonMultiButtons
@onready var btn_test_large: Button = $VBox/HBoxLarge/ButtonLarge
@onready var status_label: Label = $VBox/StatusLabel

var _test_count := 0

func _ready() -> void:
	btn_test_close.pressed.connect(_on_test_close_pressed)
	btn_test_multi_buttons.pressed.connect(_on_test_multi_buttons_pressed)
	btn_test_large.pressed.connect(_on_test_large_pressed)
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("Phase4 测试就绪\n测试背景压暗 + 模糊关闭动画")

func _on_test_close_pressed() -> void:
	_test_count += 1
	_add_status("测试: 标准弹窗关闭动画")
	PopupManager.show_popup({
		"title": "测试 " + str(_test_count),
		"content": "这是Phase4的模糊关闭动画测试\n点击按钮关闭弹窗，观察模糊效果",
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "close"}
		]
	})

func _on_test_multi_buttons_pressed() -> void:
	_test_count += 1
	_add_status("测试: 多按钮弹窗")
	PopupManager.show_popup({
		"title": "多个按钮",
		"content": "这是一个带多个按钮的弹窗\n用于测试按钮布局和点击",
		"buttons": [
			{"text": "按钮1", "type": "primary", "metadata": "btn1"},
			{"text": "按钮2", "type": "secondary", "metadata": "btn2"},
			{"text": "按钮3", "type": "third", "metadata": "btn3"}
		]
	})

func _on_test_large_pressed() -> void:
	_test_count += 1
	_add_status("测试: 大尺寸弹窗")
	PopupManager.show_popup({
		"size": "large",
		"title": "大尺寸弹窗",
		"content": "这是一个大尺寸弹窗\n用于测试不同尺寸下的动画效果",
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "close"}
		]
	})

func _on_popup_button_pressed(metadata: String) -> void:
	_add_status("收到回调: " + metadata)

func _add_status(msg: String) -> void:
	status_label.text = msg
	print("[TestPhase4] " + msg)
