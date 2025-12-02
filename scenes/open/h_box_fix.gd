extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var button_text:Array[String]=["检查启动器更新","检查游戏本体更新","访问仓库","确定"]
	var detail="由于技术有限，出现未知异常可先联系开发者确认是否为BUG\n如果需要自行解决，可下载最新版，重装解决🌹"
	var result=await WindowsManager.show_dialog("提示",detail, button_text)
	
	if result=="检查启动器更新":
		WindowsManager.version_check(1)
		return
	if result=="检查游戏本体更新":
		WindowsManager.version_check(2)
		return
	
	if result=="访问仓库":
		var button_text_1:Array[String]=["启动器","游戏本体","取消"]
		var result_0=await WindowsManager.show_dialog("选择仓库","你可以选择下面的仓库类型，你将会直接到达游戏发行版的下载页面，你可以选择直接下载最新版",button_text_1)
		if result_0=="启动器":
			OS.shell_open("https://github.com/GlacierXiaowei/ETN_Launcher/releases")
			return
		if result_0=="游戏本体":
			OS.shell_open("https://github.com/GlacierXiaowei/ETN/releases")
			return
