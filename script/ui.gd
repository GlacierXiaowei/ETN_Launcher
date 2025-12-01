# Control.gd (最终优化版)
extends Control

# --- 核心改动：统一的 Tween 管理器 ---
var current_menu_tween: Tween

@onready var menus = {
	"master": $master_menu,
	"setting": $setting_menu,
	"about": $about_menu,
	"donation": $donation_menu,
}
@onready var master_main_button = get_tree().get_nodes_in_group("master_main_button")
@onready var master_slide_button = get_tree().get_nodes_in_group("master_slide_button")
@onready var windows_preload = preload("res://scenes/windows.tscn")

func _ready() -> void:
	
	
	$zhe_zhao4.hide()
	for menu_key in menus:
		if menu_key != "master":
			var menu_node = menus[menu_key]
			menu_node.modulate.a = 0.0
			menu_node.hide()
			
	$master_menu/ui_show_animation.play("ui_show_animation")
	await $master_menu/ui_show_animation.animation_finished
	$zhe_zhao2.hide()



func _process(_delta: float) -> void:
	if $master_menu.modulate.a != 1.0:
		for button in master_main_button: button.disabled = true
		for button in master_slide_button: button.disabled = false
	else:
		for button in master_main_button: button.disabled = false
	
	if $master_menu.modulate.a == 0.0:
		for button in master_slide_button: button.disabled = true
		
# --- 升级后的中央动画函数 ---
func switch_to_submenu(menu_name: String) -> void:
	# 1. 杀死任何正在运行的旧动画，解决竞态问题！
	if is_instance_valid(current_menu_tween):
		current_menu_tween.kill()

	var target_menu = menus.get(menu_name)
	if not is_instance_valid(target_menu):
		print("试图切换到一个不存在的菜单: %s" % menu_name)
		return

	print("切换到子菜单: ", menu_name)
	$zhe_zhao4.show()
	target_menu.show() # 目标菜单必须先显示出来，才能播放动画

	# 2. 创建新的动画，并交给中央控制器管理
	current_menu_tween = get_tree().create_tween().bind_node(self)
	
	# 3. 让目标菜单淡入
	current_menu_tween.parallel().tween_property(target_menu, "modulate:a", 1.0, 0.5)

	# --- 核心改动 1：淡出所有其他菜单 ---
	# 遍历所有菜单，如果它不是我们的目标，并且它当前是可见的，就让它淡出。
	for key in menus:
		var current_menu_node = menus.get(key)
		# 检查：不是目标菜单 && 当前透明度不为0
		if key != menu_name and current_menu_node.modulate.a > 0.0:
			current_menu_tween.parallel().tween_property(current_menu_node, "modulate:a", 0.0, 0.5)

	# 4. 等待动画完成
	await current_menu_tween.finished

	# --- 核心改动 2：隐藏所有非目标菜单 ---
	# 动画结束后，再次遍历，将所有不是目标的菜单彻底隐藏
	for key in menus:
		if key != menu_name:
			menus.get(key).hide()
			
	$zhe_zhao4.hide()

# --- return 按钮处理函数 (保持不变，其逻辑已是正确的) ---
func _on_return_pressed() -> void:	
	if is_instance_valid(current_menu_tween):
		current_menu_tween.kill()

	print("返回主菜单")
	$zhe_zhao4.show()
	menus.get("master").show()

	current_menu_tween = get_tree().create_tween().bind_node(self)
	current_menu_tween.parallel().tween_property(menus.get("master"), "modulate:a", 1.0, 0.5)

	for menu_key in menus:
		if menu_key != "master":
			var sub_menu_node = menus.get(menu_key)
			if sub_menu_node.modulate.a > 0.0:
				current_menu_tween.parallel().tween_property(sub_menu_node, "modulate:a", 0.0, 0.5)

	await current_menu_tween.finished

	for menu_key in menus:
		if menu_key != "master":
			menus.get(menu_key).hide()
	$zhe_zhao4.hide()




func _on_quit_pressed() -> void:
	# 完整代码
	# 1. 实例化场景
	var windows_scene = windows_preload.instantiate()
	add_child(windows_scene)
	
	# 2. 【最终修改】设置它的尺寸为固定的 1080x1920
	windows_scene.size = Vector2(1920, 1080)
	
	# 3. 设置它的位置
	windows_scene.position = Vector2i(-352, 0)
	
	# 4. 准备参数并调用函数
	var buttons: Array[String] = ["确定", "取消"]
	windows_scene.show_dialog("提示", "你确定要退出游戏吗\\n 再一次，感谢朋友们对ETN的大力支持", buttons)
	
	
	
	
	##一下代码直接复制粘贴 
	#var windows_scene = windows_preload.instantiate()
	#add_child(windows_scene)
	# 3. 【正确做法】直接设置它的尺寸和位置
	# 获取屏幕（视口）的大小
	#var screen_size = get_viewport().get_visible_rect().size
	# 设置对话框的大小为屏幕大小
	#windows_scene.size = screen_size
	# 设置对话框的位置为屏幕左上角 (0, 0)
	#dows_scene.position = Vector2i(-352, 0)
	#由于ui节点的锚点不是覆盖全 也就是盖不住 整个游戏画面 所以需要向左偏移
	
	
	#get_node可以单独使用 并且 这里应该时实例化之后的脚本地方 应该是在ui节点之下的
	#var windows_node_get= windows_scene.get_node("/root/PanelContainer")
	
	# 检查一下是否找到了节点，这是一个好习惯
	##if windows_node_get:
  	# 4. 在正确的子节点上调用函数
	#	windows_node_get.show_dialog("提示", "你确定要退出游戏吗\\n 再一次，感谢朋友们对ETN的大力支持", ["确定", "取消"])
	#else:
	#	# 如果找不到节点，打印错误信息，方便调试
	#	print("错误：在 windows.tscn 场景中没有找到名为 'PanelContainer' 的节点！")
	
	#当脚本附加于根节点上 可以不用获取子节点 就可以直接调用
	#参数分别是 顶部文本框 中间的文字说明（可以滚动翻页） 选项的名字 
	#var button_texts: Array[String] = ["确定", "取消"]
	#windows_scene.show_dialog("提示", "你确定要退出游戏吗\\n 再一次，感谢朋友们对ETN的大力支持", button_texts)
