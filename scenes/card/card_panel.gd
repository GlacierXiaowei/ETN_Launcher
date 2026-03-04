extends Node2D

@onready var node_state_machine: NodeStateMachine = $NodeStateMachine
@onready var update_failed: Node = $NodeStateMachine/UpdateFailed
@onready var start_game: StartGame = $StartGame


func _ready() -> void:
	update_failed.reset_err_content()
	

##目前关键错误不会直接弹窗 有点何意味啊 我觉得还不如
func _on_install_test_scene_update_error_occurred(error_message: String) -> void:
	PopupManager.close_and_show_new({
		"title" : "发生错误" , "content" : error_message 
	})
	update_failed.set_err_content()
	node_state_machine.transition_to("updatefailed")

func _on_install_test_scene_update_state_changed(state: InstallSignalHub.InstallState) -> void:
	var state_name = _to_lowercase(InstallSignalHub.InstallState.keys()[state])
	##注意 这列对开始下载和开始安装不做反应 我们下载完了就要求安装 安装完了 直接进入 UpToDate 状态
	if state_name == "downloadstarted" or state_name == "installstarted" :
		return
		
	if state_name == "downloadfinished" :
		node_state_machine.transition_to("installfinished")
		return
	if state_name == "installfinished" :
		node_state_machine.transition_to("uptodate")
		return
		
	node_state_machine.transition_to(_to_lowercase(state_name))


# 将全大写下划线格式的字符串转换为全小写（无下划线）
# 例如：NOT_INSTALLED -> notinstalled, CHECKING_UPDATE -> checkingupdate, UP_TO_DATE -> uptodate
func _to_lowercase(input_str: String) -> String:
	# 处理空字符串的边界情况
	if input_str.is_empty():
		return ""
	
	# 1. 将字符串全部转为小写，然后按下划线分割成数组
	var parts = input_str.to_lower().split("_")
	var result = ""
	
	# 2. 遍历每个分割后的部分，直接拼接（无下划线）
	for part in parts:
		# 跳过空字符串（比如输入是"__TEST__"的情况）
		if part.is_empty():
			continue
		result += part
	
	return result

##这里和变量重名了 所以要用下划线
func _start_game() -> void:
	start_game.start_game()
