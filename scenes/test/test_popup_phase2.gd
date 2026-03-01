extends Control

@onready var btn_single: Button = $VBox/HBoxSingle/ButtonSingle
@onready var btn_two: Button = $VBox/HBoxTwo/ButtonTwo
@onready var btn_three: Button = $VBox/HBoxThree/ButtonThree
@onready var btn_custom_size: Button = $VBox/HBoxCustomSize/ButtonCustomSize
@onready var btn_show_confirm: Button = $VBox/HBoxShowConfirm/ButtonShowConfirm
@onready var status_label: Label = $VBox/StatusLabel

var _test_results: Array[String] = []

func _ready() -> void:
	btn_single.pressed.connect(_on_single_pressed)
	btn_two.pressed.connect(_on_two_pressed)
	btn_three.pressed.connect(_on_three_pressed)
	btn_custom_size.pressed.connect(_on_custom_size_pressed)
	btn_show_confirm.pressed.connect(_on_show_confirm_pressed)
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("Phase2 测试就绪")

func _on_single_pressed() -> void:
	_add_status("测试1: 单按钮弹窗")
	PopupManager.show_popup({
		"title": "单按钮测试",
		"content": "这是一个单按钮弹窗，验证居中/右对齐效果",
		"buttons": [
			{"text": "确定", "type": "primary", "metadata": "single_ok"}
		]
	})

func _on_two_pressed() -> void:
	_add_status("测试2: 双按钮弹窗")
	PopupManager.show_popup({
		"title": "双按钮测试",
		"content": "这是一个双按钮弹窗（取消在左，确定在右）",
		"buttons": [
			{"text": "取消", "type": "secondary", "metadata": "cancel"},
			{"text": "确定", "type": "primary", "metadata": "confirm"}
		]
	})

func _on_three_pressed() -> void:
	_add_status("测试3: 三按钮弹窗（验证右对齐）")
	PopupManager.show_popup({
		"title": "三按钮测试",
		"content": "这是一个三按钮弹窗，全部右对齐",
		"buttons": [
			{"text": "选项A", "type": "secondary", "metadata": "option_a"},
			{"text": "选项B", "type": "secondary", "metadata": "option_b"},
			{"text": "确定", "type": "primary", "metadata": "confirm"}
		]
	})

func _on_custom_size_pressed() -> void:
	_add_status("测试4: 自定义尺寸按钮")
	PopupManager.show_popup({
		"title": "自定义尺寸测试",
		"content": "大按钮 min_width=200,min_height=60\n小按钮 min_width=100,min_height=36",
		"buttons": [
			{"text": "大按钮", "type": "primary", "metadata": "big", "min_width": 200, "min_height": 60},
			{"text": "小按钮", "type": "secondary", "metadata": "small", "min_width": 100, "min_height": 36}
		]
	})

func _on_show_confirm_pressed() -> void:
	_add_status("测试5: show_confirm 快捷方法")
	PopupManager.show_confirm(
		"确认操作",
		"确定要执行此操作吗？",
		func(): _add_status("确认回调"),
		func(): _add_status("取消回调")
	)

func _on_popup_button_pressed(metadata: String) -> void:
	_add_status("收到回调: " + metadata)

func _add_status(msg: String) -> void:
	status_label.text = msg
	_test_results.append(msg)
	print("[TestPhase2] " + msg)
