extends NodeState

@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"

var title: String
var content : String
var buttons : Array


var _err_notes : String = "没有收集到错误原因。猜测可能受到了致命错误
你应该佩服作者的编程水平，你看到这条提示启动器还没崩溃。那是有点厉害了"


func _on_enter() -> void:
	state_label.text = "更新失败"


func _on_card_confirm() -> void:
	title = "更新失败"
	content = "如果错误发生在更新途中，你可以通过下列对应按钮前往对应的状态重新操作。
注意，你必须先经过一次检查更新成功才能重新进入“下载”和“安装”状态,这样你就不用重新检查更新了，否则需要重新检查更新。
累计失败原因：\n" + _err_notes
	buttons= [
		{"text": "确定" , "type" : "primary" , "metadata" : "confirm"}
	]
	if install_component._server and install_component._local:
		var ex_button_1 : Dictionary = {"text": "下载" , "type" : "secondary" , "metadata" : "download"}
		var ex_button_2 : Dictionary = {"text": "安装" , "type" : "third" , "metadata" : "install"}
		buttons.push_back(ex_button_1)
		buttons.push_back(ex_button_2)
		
	
	PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_popup({
		"title" : title , "content" : content , "buttons" : buttons
		})


func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"download":
			transition.emit("downloadstarted")
		"install":
			transition.emit("installstarted")
		"confirm":
			transition.emit("checkingupdate")


func set_err_content(err_notes :String) -> void :
	_err_notes =_err_notes + err_notes + "\n"


func reset_err_content() -> void:
	_err_notes  = "没有收集到错误原因。猜测可能受到了致命错误
你应该佩服作者的编程水平，你看到这条提示启动器还没崩溃。那是有点厉害了\n"
