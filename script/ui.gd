extends Control
var current_menu_tween: Tween

@onready var menus = {
	"master": $master_menu,
	"setting": $setting_menu,
	"about": $about_menu,
	"donation": $donation_menu,
}
@onready var master_main_button = get_tree().get_nodes_in_group("master_main_button")
@onready var master_slide_button = get_tree().get_nodes_in_group("master_slide_button")

@onready var status_label = $master_menu/headline/top_label
#↑ 这个是 最顶部的文字
@onready var game_begin_button = $master_menu/game_begin
@onready var version_check_button = $master_menu/version_check
var is_manager_busy = false

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
	## --- 【修正】确保使用正确的单例名称 WindowsManager ---
	#if not Engine.has_singleton("WindowsManager"):
		#push_error("严重错误：WindowsManager 未被注册为 Autoload 单例！")
		#status_label.text = "错误：核心管理器未加载"
		#return
		#
	#WindowsManager.status_changed.connect(_on_manager_status_changed)
	#修改单例 现在的检查更新的状态是 ”初始状态“
	var initial_status = SetUpInfo.UpdateStatus.IDLE
	if !FileAccess.file_exists(WindowsManager.get_game_executable_path()):
		initial_status=SetUpInfo.UpdateStatus.NOT_INSTALLED
	#类状态机 ↑ 状态以切换
	_on_manager_status_changed(initial_status, SetUpInfo.get_status_message(initial_status))

func _process(_delta: float) -> void:
	pass
	#以下为 动画相关 如果主场景中的两个主要按钮正在被使用 那么禁用点击
	#目前想改以下
	#var is_animating = ($master_menu.modulate.a != 1.0)
	#for button in master_main_button:
		#button.disabled = is_manager_busy or is_animating
	#for button in master_slide_button:
		#button.disabled = is_manager_busy or ($master_menu.modulate.a == 0.0)
		#if is_animating:
			#button.disabled = false
	#↑ 其实可以用状态机优化的 懒得 算了

func switch_to_submenu(menu_name: String) -> void:
	#↓ 这个是产生新动画的时候 打断旧的
	if is_instance_valid(current_menu_tween):
		current_menu_tween.kill()
		
	var target_menu = menus.get(menu_name)
	if not is_instance_valid(target_menu):
		print("试图切换到一个不存在的菜单: %s" % menu_name)
		return
	print("切换到子菜单: ", menu_name)
	$zhe_zhao4.show()
	target_menu.show() 
	#这个bind_node 将该tween绑定到self 节点中 两者生命周期一致 并且 内存管理跟随self节点
	#也只有 self被加载到内存 才会开始执行
	current_menu_tween = get_tree().create_tween().bind_node(self)
	current_menu_tween.parallel().tween_property(target_menu, "modulate:a", 1.0, 0.5)
	
	for key in menus:
		var current_menu_node = menus.get(key)
		if key != menu_name and current_menu_node.modulate.a > 0.0:
			current_menu_tween.parallel().tween_property(current_menu_node, "modulate:a", 0.0, 0.5)
	await current_menu_tween.finished
	#动画结束后 隐藏 防止错误点击到透明的东西
	for key in menus:
		if key != menu_name:
			menus.get(key).hide()
	$zhe_zhao4.hide()
#该函数代码已经经过实践 ↑ 不需要修改

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
	var detail="确定要退出吗？\n感谢你的安装和游玩！\n非常感谢大家的支持，再一次，谢谢各位朋友们"
	var result = await WindowsManager.show_dialog("提示", detail, button_text)
	if result == "确定":
		get_tree().quit()

func _on_game_begin_pressed() -> void:
	# 使用 WindowsManager
	WindowsManager.launch_game()

func _on_version_check_pressed() -> void:
	# 使用 WindowsManager
	VersionCheck.start_update_check()

func _on_manager_status_changed(status: SetUpInfo.UpdateStatus, message: String) -> void:
	#这行代码有点多余 debug模式 打开之后再显示吧1 代码还没弄好啊
	status_label.text = message
	is_manager_busy = (
		#注意 这是合理的 换行加缩进 相当于连在一起的 哈 可以这么写哦
		status == SetUpInfo.UpdateStatus.CHECKING or
		status == SetUpInfo.UpdateStatus.DOWNLOADING or
		status == SetUpInfo.UpdateStatus.UNZIPPING
	)
	#强制传递值 仅本次调用不再等待下一帧再执行，而是立即执行
	_process(0.0) 
	
	#相当于 switch
	match status:
		
		SetUpInfo.UpdateStatus.NEEDS_UPDATE:
			game_begin_button.text = "需要更新"
		SetUpInfo.UpdateStatus.NOT_INSTALLED:
			game_begin_button.text = "未安装"        
		#这个 \ 是续行符 就是 换行不中断 这是为了 代码美观
		SetUpInfo.UpdateStatus.UP_TO_DATE, \
		SetUpInfo.UpdateStatus.INSTALL_COMPLETE:
			game_begin_button.text = "启动游戏"
		SetUpInfo.UpdateStatus.FAIL_TO_CHECK, \
		SetUpInfo.UpdateStatus.DOWNLOAD_FAILED, \
		SetUpInfo.UpdateStatus.FAIL_TO_UNZIP:
			game_begin_button.text = "安装失败"
