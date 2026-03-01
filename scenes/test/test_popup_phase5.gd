extends Control

@onready var btn_confirm_x3: Button = $VBox/HBox1/BtnConfirmX3
@onready var btn_alert_x3: Button = $VBox/HBox1/BtnAlertX3
@onready var btn_popup_to_loading: Button = $VBox/HBox2/BtnPopupToLoading
@onready var btn_hide_loading_restore: Button = $VBox/HBox2/BtnHideLoadingRestore
@onready var btn_show_loading_no_popup: Button = $VBox/HBox3/BtnShowLoadingNoPopup
@onready var btn_hide_loading_restore_config: Button = $VBox/HBox3/BtnHideLoadingRestoreConfig
@onready var status_label: Label = $VBox/StatusLabel

var _confirm_calls := 0
var _alert_calls := 0

func _ready() -> void:
	btn_confirm_x3.pressed.connect(_on_confirm_x3)
	btn_alert_x3.pressed.connect(_on_alert_x3)
	btn_popup_to_loading.pressed.connect(_on_popup_to_loading)
	btn_hide_loading_restore.pressed.connect(_on_hide_loading_restore)
	btn_show_loading_no_popup.pressed.connect(_on_show_loading_no_popup)
	btn_hide_loading_restore_config.pressed.connect(_on_hide_loading_restore_config)
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("Phase5 测试就绪")


func _on_confirm_x3() -> void:
	_confirm_calls = 0
	_add_status("测试: show_confirm x3 (回调不应累积)")
	for i in range(3):
		PopupManager.show_confirm(
			"Confirm #" + str(i + 1),
			"每次只应触发一次 on_confirm 回调",
			func() -> void:
				_confirm_calls += 1
				print("[Phase5] confirm callback calls = ", _confirm_calls)
		)


func _on_alert_x3() -> void:
	_alert_calls = 0
	_add_status("测试: show_alert x3 (回调不应累积)")
	for i in range(3):
		PopupManager.show_alert(
			"Alert #" + str(i + 1),
			"每次只应触发一次 on_ok 回调",
			func() -> void:
				_alert_calls += 1
				print("[Phase5] alert callback calls = ", _alert_calls)
		)


func _on_popup_to_loading() -> void:
	_add_status("测试: 现有弹窗 -> show_loading (不改 richtext，只改按钮/label)")
	PopupManager.show_popup({
		"title": "普通弹窗",
		"content_type": "richtext",
		"content": "[b]RichText 保持不变[/b]\n接下来进入 loading 状态",
		"buttons": [
			{"text": "进入 Loading", "type": "primary", "metadata": "go_loading"},
			{"text": "关闭", "type": "secondary", "metadata": "close"}
		]
	})


func _on_hide_loading_restore() -> void:
	_add_status("测试: hide_loading() 快照恢复")
	PopupManager.hide_loading({}, true)


func _on_show_loading_no_popup() -> void:
	_add_status("测试: 无弹窗 -> show_loading 自动创建等待弹窗")
	PopupManager.show_loading("请稍候", "请稍候...", true)


func _on_hide_loading_restore_config() -> void:
	_add_status("测试: hide_loading(restore_config) 切换为可交互态")
	PopupManager.hide_loading({
		"title": "操作完成",
		"content_type": "label",
		"content": "现在可以继续操作了",
		"buttons": [
			{"text": "继续", "type": "primary", "metadata": "continue"},
			{"text": "关闭", "type": "secondary", "metadata": "close"}
		]
	}, true)


func _on_popup_button_pressed(metadata: String) -> void:
	_add_status("收到回调: " + metadata)
	match metadata:
		"go_loading":
			PopupManager.show_loading("", "", true)
			# Simulate some work then restore via snapshot.
			await get_tree().create_timer(1.0).timeout
			PopupManager.hide_loading({}, true)
			_add_status("Loading -> 快照恢复完成")
		"close":
			PopupManager.close_popup()
		"continue":
			print("[Phase5] user continues")


func _add_status(msg: String) -> void:
	status_label.text = msg
	print("[TestPhase5] " + msg)
