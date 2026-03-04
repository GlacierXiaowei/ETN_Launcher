extends NodeState

@onready var card_panel: Node2D = $"../.."
@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
var buttons : Array

func _on_enter() -> void:
	state_label.text = "游戏中"
	##关闭启动器音乐 如果可以 可以把启动器 窗口最小化 
	##todo 注意 不能让启动器自己关闭 要有确认 这个别忘了 不过忘不掉吧 这么关键的功能
	##然后我们做一个shader吧  首先这个溶解要做 然后溶解结束后 我想这怎么也启动了吧 
	##就上一个新的shader?  比如光芒转圈圈 ？ 或者 为了节约性能 切换场景？ 我觉得可以切换场景吧
	##话说 我们鼠标焦点离开窗口 会不会出发float ?
	

func _on_card_confirm() -> void:
	pass
	##下次做  游戏中 文是否要重启 我们先关闭 然后启动 这个考虑使用call_deffer
