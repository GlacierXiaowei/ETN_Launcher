extends NodeState


@onready var state_label: Label = $"../../DownShadow/StateLabel"

@onready var install_component: InstallComponent = $"../../InstallComponent"
@onready var card_panel: Node2D = $"../.."


var title: String
var content : String
var buttons : Array

func _on_enter() -> void:
	state_label.text = "检查更新失败"


func _on_card_confirm() -> void:
	title = "检查更新失败"
	content = "请尝试10分钟之后再试，检查更新失败属于正常的网络波动。
如若检查更新失败也可离线游玩，游戏存档等功能将不受影响。
您现在可选择直接离线进入或者重新尝试检查更新。
以下为错误信息：\n		" + install_component._server.err_notes + "\n如果要使用自定义更新，可前往设置放入本地的标准补丁包或游戏zip文件"
	buttons= [
		{"text": "重试" , "type" : "primary" , "metadata" : "retry"},
		{"text": "离线进入" , "type" : "secondary" , "metadata" : "enter"},
		{"text": "取消" , "type" : "third" , "metadata" : "cancel"}
	]
	
	PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_popup({
		"title" : title , "content" : content , "buttons" : buttons
		})
	
func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"retry":
			install_component.re_ready()
		"enter":
			card_panel._start_game()
		"cancel":
			pass
	
	
