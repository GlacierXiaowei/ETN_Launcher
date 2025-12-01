# VBoxContainer.gd
extends VBoxContainer

@onready var node_ui = get_node("../..")

# 这个脚本现在只负责一件事：
# 告诉它的父节点（也就是 Control 节点）用户点击了哪个按钮。
func _on_menu_button_pressed(menu_name: String) -> void:
	# owner 指的是该节点的父节点，也就是 ui (Control) 节点
	# 我们调用 Control 节点上即将创建的 switch_to_submenu 方法
	# 注意：这里的 "setting" 字符串必须是干净的，不带引号
	owner.switch_to_submenu(menu_name)

func _on_quit_pressed() -> void:
	
	
	#直接复制粘贴就好 以下代码 只需要 
	#@onready 是因为 我们需要获取到ui脚本下的预加载场景
	var windows_var=node_ui.windows
	
	
	
	#get_tree().quit()
