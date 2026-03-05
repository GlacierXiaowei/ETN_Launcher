extends NodeState


@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"




var title: String
var content : String
var buttons : Array

func _on_enter() -> void:
	install_component.re_ready()
		
	state_label.text = "未安装"


func _on_card_confirm() -> void:
	title = "未安装"
	content = "感谢您选择冰川氏互娱，感谢您支持冰川小未！\n点击[wave]获取[/wave]最新版本完整包，按照指示即可安装游戏！ \n 如果出现网络问题，请10分钟之后再试，属于正常的网络波动。"
	buttons= [
		{"text": "获取" , "type" : "primary" , "metadata" : "confirm"},
		{"text": "取消" , "type" : "secondary" , "metadata" : "cancel"}
	]
	PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_popup({
		"title" : title , "content" : content , "buttons" : buttons
		})
	
func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"confirm":
			install_component.reset_version()
			install_component.is_installed = true
			await get_tree().process_frame
			install_component.re_ready()
	
	
