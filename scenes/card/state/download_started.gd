extends NodeState


@onready var state_label: Label = $"../../DownShadow/StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
var buttons : Array

var _is_force_update : bool
var _is_force_full_package : bool


func _on_card_confirm() -> void:
	self._start_download()
	

func _on_enter() -> void:
	_is_force_full_package = install_component._server.force_full_package
	_is_force_update =  install_component._server.force_update
	state_label.text = "正在下载"
	
	# 先关闭之前的弹窗（如果有），避免时序问题
	if PopupManager.has_open_popup():
		PopupManager.close_popup()
		await get_tree().create_timer(0.6).timeout  # 等待关闭动画完成
	 
	if _is_force_full_package == false:
		install_component._on_下载_pressed()
	_start_download()

func _start_download() -> void:
	##选择文件这一块 我们先告知 点击确定才会进入浏览器下载
	title = "开始下载"
	match _is_force_full_package:
		
		true:
			content = "点击确定我们将会启动浏览器下载，点击之后本窗口不会关闭\n本次下载需要你们找到文件所在位置请在浏览器下载完成之后，点击 [wave] 安装 [/wave] 选择文件并启动下载安装服务
下一个弹窗会有相关教程。\n如果您在安装过程中出现错误，原则上您下载的文件我们不会删除，您可直接选择安装重新操作
如果始终无法成功，请联系作者"

			buttons= [
				{"text": "下载" , "type" : "primary" , "metadata" : "download"},
				{"text": "安装" , "type" : "secondary" , "metadata" : "install"},
				{"text": "取消" , "type" : "third" , "metadata" : "cancel"}
					]
	
			PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
			PopupManager.show_popup({
				"title" : title , "content" : content , "buttons" : buttons 
									})
		false:
			PopupManager.show_loading("正在下载","耐心等待。一般来说，下载流程较快。如果出现报错，我们将会及时通知你。")



func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		"download":
			install_component._on_下载_pressed()
		"install":
			transition.emit("InstallStarted")
		"cancel":
			transition.emit("NeedUpdate")
	
	
