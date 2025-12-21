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
func _ready() -> void:
	
	$master_menu/zhe_zhao3.focus_mode=Control.FOCUS_NONE
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
	var button_text:Array[String]=["确定","取消"]
	var detail="确定要退出吗？
非常感谢大家的支持，再一次，谢谢各位朋友们"
	var result=await WindowsManager.show_dialog("提示",detail, button_text)
	
	
	if result=="确定":
		get_tree().quit()
	else:
		pass
	pass


func _on_game_begin_pressed() -> void:
	
	#注意 text没有负数 
	#var result=await WindowsManager.show_dialog("提示",detail, button_text)
	var text_button:Array[String]=["确定","取消"]
	var result=await WindowsManager.show_dialog("提示","当你看到这条提示的时候，说明游戏还没有制作完毕\n（除非你的启动器不是最新版）\n点击确定查看作者的游戏开发进展和阶段性计划（实时更新）",text_button)
	if result=="确定":
		WindowsManager.version_check(2)
	#1：只检查启动器更新
	
func _on_version_check_pressed() -> void:
	var button_text:Array[String]=["启动器","游戏本体","取消"]
	#注意 text没有负数 
	#var result=await WindowsManager.show_dialog("提示",detail, button_text)
	var detail="请选择你希望检查更新的类型：
你可以分开检查启动器更新和游戏本体的更新
请确保科学上网
再一次，感谢朋友们的支持"
	var result=await WindowsManager.show_dialog("提示",detail, button_text)
	#1代表启动器更新 2代表游戏本体
	if result=="启动器":
	
		WindowsManager.version_check(1)
		print("已经开始检查更新")
	
	if result=="游戏本体":
		print("已经开始检查更新")
		
		WindowsManager.version_check(2)
		#游戏包体为2
