extends Control

@onready var btn_update_content: Button = $VBox/HBoxUpdate/ButtonUpdateContent
@onready var btn_update_with_fade: Button = $VBox/HBoxUpdateFade/ButtonUpdateFade
@onready var btn_close_and_new: Button = $VBox/HBoxCloseNew/ButtonCloseNew
@onready var btn_has_popup: Button = $VBox/HBoxHasPopup/ButtonHasPopup
@onready var status_label: Label = $VBox/StatusLabel

var _step := 0

func _ready() -> void:
	btn_update_content.pressed.connect(_on_update_content_pressed)
	btn_update_with_fade.pressed.connect(_on_update_with_fade_pressed)
	btn_close_and_new.pressed.connect(_on_close_and_new_pressed)
	btn_has_popup.pressed.connect(_on_has_popup_pressed)
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("Phase3 测试就绪")

func _on_update_content_pressed() -> void:
	_add_status("测试1: 单弹窗内容更新")
	_step = 1
	PopupManager.show_popup({
		"title": "步骤 1/3",
		"content": "这是第一步\n点击\"下一步\"继续",
		"buttons": [
			{"text": "下一步", "type": "primary", "metadata": "next", "stay_open": true},
			{"text": "取消", "type": "secondary", "metadata": "cancel"}
		]
	})

func _on_update_with_fade_pressed() -> void:
	_add_status("测试2: 带淡入淡出的内容更新")
	_step = 10
	PopupManager.show_popup({
		"title": "阶段 A",
		"content": "这是阶段 A\n点击\"进入下一阶段\"继续",
		"buttons": [
			{"text": "进入下一阶段", "type": "primary", "metadata": "next_fade", "stay_open": true},
			{"text": "退出", "type": "secondary", "metadata": "cancel"}
		],
		"transition_animation": true
	})

func _on_close_and_new_pressed() -> void:
	_add_status("测试3: 关闭后打开新弹窗")
	_step = 20
	PopupManager.show_popup({
		"title": "第一个弹窗",
		"content": "点击按钮关闭此弹窗并打开新弹窗",
		"buttons": [
			{"text": "关闭并打开新弹窗", "type": "primary", "metadata": "close_and_show"}
		]
	})

func _on_has_popup_pressed() -> void:
	_add_status("测试4: has_open_popup() 检查")
	var has_popup := PopupManager.has_open_popup()
	_add_status("当前是否有弹窗: " + ("是" if has_popup else "否"))

func _on_popup_button_pressed(metadata: String) -> void:
	_add_status("收到回调: " + metadata)
	
	match metadata:
		"next":
			if _step == 1:
				_step = 2
				PopupManager.update_popup({
					"title": "步骤 2/3",
					"content": "这是第二步\n再点击\"下一步\"继续",
					"buttons": [
						{"text": "下一步", "type": "primary", "metadata": "next"},
						{"text": "取消", "type": "secondary", "metadata": "cancel"}
					]
				})
		"next_fade":
			if _step == 10:
				_step = 11
				PopupManager.update_popup({
					"title": "阶段 B",
					"content": "这是阶段 B\n淡入淡出效果完成",
					"buttons": [
						{"text": "完成", "type": "primary", "metadata": "finish"}
					]
				})
		"close_and_show":
			if _step == 20:
				_step = 21
				PopupManager.close_and_show_new({
					"title": "新弹窗",
					"content": "这是新打开的弹窗\n上一个弹窗已关闭",
					"buttons": [
						{"text": "关闭", "type": "primary", "metadata": "ok"}
					]
				})

func _add_status(msg: String) -> void:
	status_label.text = msg
	print("[TestPhase3] " + msg)
