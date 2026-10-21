extends Control

@onready var status_label: Label = $VBox/StatusLabel

var _confirm_calls := 0
var _alert_calls := 0
var _confirm_step := 0
var _alert_step := 0

func _ready() -> void:
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	_add_status("Phase5 测试就绪 - 正在打开测试菜单弹窗")
	await get_tree().process_frame
	_open_menu_popup()


func _open_menu_popup() -> void:
	PopupManager.show_popup({
		"title": "Phase5 测试菜单",
		"content_type": "label",
		"content": "请在弹窗内点击按钮触发测试（避免背景遮罩吸收输入）。",
		"buttons": [
			{"text": "Confirm 连续3次", "type": "primary", "metadata": "menu_confirm_x3", "stay_open": true},
			{"text": "Alert 连续3次", "type": "secondary", "metadata": "menu_alert_x3", "stay_open": true},
			{"text": "Popup -> Loading", "type": "secondary", "metadata": "menu_popup_to_loading", "stay_open": true},
			{"text": "No popup -> show_loading", "type": "third", "metadata": "menu_show_loading_no_popup", "stay_open": true},
			{"text": "hide_loading(restore_config)", "type": "third", "metadata": "menu_hide_loading_restore_config", "stay_open": true}
		]
	})



func _run_confirm_x3() -> void:
	_confirm_calls = 0
	_confirm_step = 1
	_add_status("测试: 连续弹 3 次 confirm（验证快捷回调不会累积）")
	_show_confirm_step()


func _show_confirm_step() -> void:
	var step := _confirm_step
	var on_ok := func() -> void:
		_confirm_calls += 1
		print("[Phase5] confirm callback calls = ", _confirm_calls)
		_confirm_step += 1
		if _confirm_step <= 3:
			_show_confirm_step()
		else:
			_open_menu_popup()
	
	var on_cancel := func() -> void:
		_open_menu_popup()
	
	PopupManager.show_confirm(
		"Confirm " + str(step) + "/3",
		"每次点击【确定】只应触发一次回调；不应发生历史回调累积。",
		on_ok,
		on_cancel
	)



func _run_alert_x3() -> void:
	_alert_calls = 0
	_alert_step = 1
	_add_status("测试: 连续弹 3 次 alert（验证快捷回调不会累积）")
	_show_alert_step()


func _show_alert_step() -> void:
	var step := _alert_step
	var on_ok := func() -> void:
		_alert_calls += 1
		print("[Phase5] alert callback calls = ", _alert_calls)
		_alert_step += 1
		if _alert_step <= 3:
			_show_alert_step()
		else:
			_open_menu_popup()
	
	PopupManager.show_alert(
		"Alert " + str(step) + "/3",
		"每次点击【确定】只应触发一次回调；不应发生历史回调累积。",
		on_ok
	)



func _run_popup_to_loading() -> void:
	_add_status("测试: 现有弹窗 -> 按钮触发 show_loading (按钮需 stay_open)")
	PopupManager.show_popup({
		"title": "普通弹窗",
		"content_type": "richtext",
		"content": "[b]RichText 保持不变[/b]\n点击按钮进入 loading（按钮必须 stay_open，否则弹窗会按默认逻辑关闭）",
		"buttons": [
			{"text": "进入 Loading", "type": "primary", "metadata": "start_loading", "stay_open": true},
			{"text": "关闭", "type": "secondary", "metadata": "close"}
		]
	})


func _run_show_loading_no_popup() -> void:
	_add_status("测试：无弹窗分支 show_loading（先关闭菜单弹窗，再显示等待态，最后恢复菜单）")
	print("[TestPhase5] _run_show_loading_no_popup: 开始执行")
	print("[TestPhase5] _run_show_loading_no_popup: has_open_popup() =", PopupManager.has_open_popup())
	if PopupManager.has_open_popup():
		print("[TestPhase5] _run_show_loading_no_popup: 正在调用 close_popup()")
		PopupManager.close_popup()
		# Close animation is ~0.4s, wait 0.7s to be safe.
		print("[TestPhase5] _run_show_loading_no_popup: 等待 0.7 秒...")
		await get_tree().create_timer(0.7).timeout
		print("[TestPhase5] _run_show_loading_no_popup: 等待完成，准备调用 show_loading()")
	print("[TestPhase5] _run_show_loading_no_popup: 调用 show_loading()")
	PopupManager.show_loading("请稍候", "请稍候...", true)
	print("[TestPhase5] _run_show_loading_no_popup: show_loading() 返回")
	await get_tree().create_timer(1.0).timeout
	print("[TestPhase5] _run_show_loading_no_popup: 调用 hide_loading()")
	PopupManager.hide_loading({
		"title": "Phase5 测试菜单",
		"content_type": "label",
		"content": "请在弹窗内点击按钮触发测试（避免背景遮罩吸收输入）。",
		"buttons": [
			{"text": "Confirm 连续 3 次", "type": "primary", "metadata": "menu_confirm_x3", "stay_open": true},
			{"text": "Alert 连续 3 次", "type": "secondary", "metadata": "menu_alert_x3", "stay_open": true},
			{"text": "Popup -> Loading", "type": "secondary", "metadata": "menu_popup_to_loading", "stay_open": true},
			{"text": "No popup -> show_loading", "type": "third", "metadata": "menu_show_loading_no_popup", "stay_open": true},
			{"text": "hide_loading(restore_config)", "type": "third", "metadata": "menu_hide_loading_restore_config", "stay_open": true}
		],

		"transition_animation": true,
	}, true)


func _run_hide_loading_restore_config() -> void:
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
		"menu_confirm_x3":
			_run_confirm_x3()
		"menu_alert_x3":
			_run_alert_x3()
		"menu_popup_to_loading":
			_run_popup_to_loading()
		"menu_show_loading_no_popup":
			await _run_show_loading_no_popup()
		"menu_hide_loading_restore_config":
			_run_hide_loading_restore_config()
		"start_loading":
			PopupManager.show_loading("", "", true)
			await get_tree().create_timer(1.0).timeout
			PopupManager.hide_loading({}, true)
			_add_status("Loading -> 快照恢复完成")
		"close":
			PopupManager.close_popup()
		"continue":
			print("[Phase5] user continues")
			PopupManager.close_popup()


func _add_status(msg: String) -> void:
	status_label.text = msg
	print("[TestPhase5] " + msg)
