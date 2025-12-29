extends Node

var _windows_preload = preload("res://scenes/windows.tscn") # 弹窗场景
var window :PanelContainer

func _ready():
	pass
func launch_game():
	var exe_path = get_game_executable_path()
	if FileAccess.file_exists(exe_path):
		OS.shell_open(exe_path)
		show_simple_dialog("正在拉起进程", "为了保证游戏文件完整性，启动器和本体不能同时运行，启动器将在3s后退出")
		await get_tree().create_timer(3.5).timeout
		get_tree().quit() # 关闭启动器
	else:
		
		show_simple_dialog("启动失败", "找不到游戏执行文件！\n请尝试检查更新或重新安装。")

func show_dialog(alarm_text: String, detail_text: String, button_texts: Array[String]) -> String:
	if is_instance_valid(window):
		window.queue_free()
	window = _windows_preload.instantiate()
	add_child(window)
	window.show_dialog(alarm_text, detail_text, button_texts)
	var result = await window.complete
	
	return result

# 封装一个更简单的弹窗，用于只通知、不需要等待用户选择的场景
func show_simple_dialog(alarm_text: String, detail_text: String):
	show_dialog(alarm_text, detail_text, ["确定"])

# 获取游戏可执行文件的路径 (你的函数)
func get_game_executable_path() -> String:
	return "user://game/Embody The Now.exe"
	
