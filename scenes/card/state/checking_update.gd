extends NodeState

@onready var state_label: Label = $"../../DownShadow/StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
#var buttons : Array

func _on_enter() -> void:
	state_label.text = "正在检查更新"


func _on_card_confirm() -> void:
	title = "请稍后"
	content = "正在检查更新，请耐心等待。如果出现网络问题，请10分钟之后再试，属于正常的网络波动。\n如若检查更新失败也可离线游玩，游戏存档等功能将不受影响。"
	#PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_confirm(title,content)
	
	
#func on_popup_button_pressed(metadata : String) -> void:
	#match metadata:
		#"confirm":
			#install_component.reset_version()
			#install_component.re_ready()
	
	
