extends NodeState


@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
var buttons : Array

var _is_force_update : bool
var _is_force_full_package : bool


func _on_card_confirm() -> void:
	self._on_enter()
	

func _on_enter() -> void:
	_is_force_full_package = install_component._server.force_full_package
	_is_force_update =  install_component._server.force_update
	state_label.text = "正在安装"
	
	##选择文件这一块 我们先告知 点击确定才会进入浏览器下载
	title = "开始安装"
	match _is_force_full_package:
		false:
			PopupManager.show_alert(title,"点击确定自动安装", func():wait_for_install() )
		true:
			content = "我们支持通过
1.文件浏览器窗口选择文件进行安装
2.复制下载路径安装
以下有复制路径的教程 （可以滚轮滑动向下翻页）
如遇到问题 可向开发者反馈 （本来我也不想这么做 但是之前我的Http的连接速度太慢 只能让你们浏览器处理啦 理解万岁！）"

			buttons= [
				{"text": "浏览" , "type" : "primary" , "metadata" : "primary"},
				{"text": "路径" , "type" : "secondary" , "metadata" : "secondary"},
				{"text": "取消" , "type" : "third" , "metadata" : "cancel"}
					]
	
			PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
			PopupManager.show_popup({
				"title" : title , "content" : content , "buttons" : buttons 
									})
		


func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"primary":
			install_component._on_选择自定义文件_pressed(false)
		"secondary":
			install_component._on_选择自定义文件_pressed(true)
		"cancel":
			transition.emit("NeedUpdate")
	
	
func wait_for_install()-> void:
	PopupManager.show_loading("","请等待安装完成",true)
	##这里是为了防止动画出问题
	await get_tree().create_timer(0.5).timeout
	install_component._on_开始安装_pressed() 
