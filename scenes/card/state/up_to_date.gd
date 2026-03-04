extends NodeState

@onready var card_panel: Node2D = $"../.."
@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
var buttons : Array

func _on_enter() -> void:
	state_label.text = "启动游戏"


func _on_card_confirm() -> void:
	card_panel._start_game()
	#title = "检查更新失败"
	#content = "请尝试10分钟之后再试，检查更新失败属于正常的网络波动。
	#如若检查更新失败也可离线游玩，游戏存档等功能将不受影响。
	#您现在可选择直接离线进入或者重新尝试检查更新。
	#以下为错误信息：\n  "
	#buttons= [
		#{"text": "重试" , "type" : "primary" , "metadata" : "retry"},
		#{"text": "离线进入" , "type" : "secondary" , "metadata" : "enter"},
		#{"text": "取消" , "type" : "third" , "metadata" : "cancel"}
	#]
	#
	#PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	#PopupManager.show_popup({
		#"title" : title , "content" : content , "buttons" : buttons
		#})
	
#func on_popup_button_pressed(metadata : String) -> void:
	#match metadata:
		#"enter":
			#pass##还没填充进入游戏的系统呢
