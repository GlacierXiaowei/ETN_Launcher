extends NodeState


@onready var state_label: Label = $"../../DownShadow/StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"
@onready var card_panel: Control = $"../.."


var title: String
var content : String
var buttons : Array

var _is_force_update : bool
var _is_force_full_package : bool

func _on_enter() -> void:
	_is_force_full_package = install_component._server.force_full_package
	_is_force_update =  install_component._server.force_update
	if _is_force_update:
		state_label.text = "需要更新"
		title = "需要更新"
	else:
		state_label.text = "需要注意"
		title = "需要注意"


func _on_card_confirm() -> void:
	content = "当前有可用更新，点击[wave]更新[/wave]启动下载安装服务\n"
	if _is_force_full_package:
		content += "本次更新需要前往浏览器下载完整包并需要自定义选择安装包\n"
	if _is_force_update:
		content += "请注意，您必须完成本次更新才能进入游戏。😉\n"
	content += install_component._server.update_notes
	content += "\n注意：以下为更新规则
	1.游戏的基础版本低于最低兼容版本本次更新将会要求全量更新 
	2.存在新的可用补丁或者缺少补丁推荐更新（速度很快）
	3.若新版本要求全量更新那么更新时必须使用全量下载
	4.若新版本要求必须更新，则必须更新游戏才能进入游戏"
   
	buttons= [
		#{"text": "全量下载" , "type" : "secondary" , "metadata" : "full_update"},
		{"text": "更新" , "type" : "primary" , "metadata" : "update"},
		{"text": "取消" , "type" : "third" , "metadata" : "cancel"}
	]
	if _is_force_update:
		buttons.push_back({"text": "离线进入" , "type" : "secondary" , "metadata" : "enter"})
	
	PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_popup({
		"title" : title , "content" : content , "buttons" : buttons ,"size" : "large"
		})
	
func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"update":
			transition.emit("downloadstarted")
			#这个我们让下一个节点处理吧
			#install_component._on_下载_pressed()
		"enter":
			card_panel._start_game()
		"cancel":
			pass
	
	
