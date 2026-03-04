extends Node
class_name InstallComponent
@export var update_choose_file: Node

@export var game_name : String = "ETN_Farm"

@onready var uptate_type_control: Node = $Component/UptateTypeControl
@onready var update_flow: Node = $Component/UpdateFlow
@onready var update_ui_manager: Node = $Component/UpdateUiManager
@onready var signal_hub: Node = $Component/InstallSignalHub

##这指向APPDATA文件夹
var game_dir = OS.get_environment("APPDATA")
##这直接指向用户数据文件夹位置
var user_path = game_dir.path_join(game_name)
var is_installed: bool = false
var _local : VersionInfo
var _server : UpdatePolicy

##别忘记填充了 免得反复检查 
var is_up_to_data : bool = false

#signal update_needed(result: String)
#signal up_to_date
signal update_state_changed(state: InstallSignalHub.InstallState)
signal update_error_occurred(error_message: String)


func check_game_installation() -> bool:
	is_installed = VersionUtils.check_game_installed(game_name, user_path)
	return is_installed


func reset_version() -> bool:
	return VersionUtils.reset_version(user_path)


func _ready() -> void:
	if signal_hub:
		signal_hub.state_changed.connect(_on_hub_state_changed)
		signal_hub.error_occurred.connect(_on_hub_error)
	
	check_game_installation()
	if not is_installed:
		update_state_changed.emit(InstallSignalHub.InstallState.NOT_INSTALLED)
		return
	
	await init_check_version()
	if _server.force_full_package:
		update_choose_file.copy_path ="user://download/full/"
	else:
		update_choose_file.copy_path ="user://download/patch/"


##用于外部调用 来重置检查更新 这将会不会导致信号重复链接 同时依然会检查游戏是否存在(需要手动调用reset_version) 但是会重置_server和_local
##GDScript 在处理类的new时 会自动管理内存泄漏问题：自动delete未被“指针”引用的对象 所以我们直接新建就可以
##但是安全起见 等玩家反馈再修复 手动清除吧 
func re_ready() -> void:
	check_game_installation()
	if not is_installed:
		update_state_changed.emit(InstallSignalHub.InstallState.NOT_INSTALLED)
		return
	await init_check_version()
	if _server.force_full_package:
		update_choose_file.copy_path ="user://download/full/"
	else:
		update_choose_file.copy_path ="user://download/patch/"


##用于检测自定义更新是否完成所有更新流程/是否安装完所有补丁
func verify_version() -> bool:
	if not _local or not _local:
		update_error_occurred.emit("非法使用函数： verify_version。\n使用之前必须先初始化检查更新组件")
		return false
	var checker = UpdateChecker.new()
	var result = checker.check(_local, _server)
	print("  - 比较结果：", result)
	checker.queue_free()
	
	match result:
		"UP_TO_DATE":
			print("\n[结果] 已是最新版本，无需更新")
			update_state_changed.emit(InstallSignalHub.InstallState.UP_TO_DATE)
			return true
			
		"FULL_UPDATE_REQUIRED":
			print("\n[结果] 需要全量更新")
			_server.force_full_package = true
			update_state_changed.emit(InstallSignalHub.InstallState.NEED_UPDATE)
			return false
			
		"NORMAL_UPDATE_REQUIRED":
			print("\n[结果] 需要补丁更新")
			update_state_changed.emit(InstallSignalHub.InstallState.NEED_UPDATE)
			return false
			
		_:
			print("\n[结果] 未知状态：", result)
			update_state_changed.emit(InstallSignalHub.InstallState.CHECK_FAILED)
			return false
			
		
func init_check_version() -> void:
	if not is_installed:
		update_state_changed.emit(InstallSignalHub.InstallState.NOT_INSTALLED)
		return
	
	if is_up_to_data :
		update_state_changed.emit(InstallSignalHub.InstallState.UP_TO_DATE)
		return
	
	print("========== 开始流程 ==========")
	print("用户目录：", user_path)
	print("\n[步骤 1] 获取本地版本信息...")
	var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
	_local = local
	print("  - base_version: ", local.base_version)
	print("  - base_patch_max: ", local.base_patch_max)
	print("  - equal_version: ", local.equal_version)
	print("  - game_name: ", local.game_name)
	
	
	update_state_changed.emit(InstallSignalHub.InstallState.CHECKING_UPDATE)
	print("\n[步骤 2] 获取服务器更新策略...")
	
	var server = await VersionUtils.get_update_policy(game_name)
	_server=server
	
	if server.target_version == "":
		print("  [错误] 获取服务器策略失败")
		update_state_changed.emit(InstallSignalHub.InstallState.CHECK_FAILED)
		return
		
	print("  - min_supported_version: ", server.min_supported_version)
	print("  - target_version: ", server.target_version)
	print("  - target_patch: ", server.target_patch)
	print("  - force_update: ", server.force_update)
	print("  - force_full_package: ", server.force_full_package)
	print("  - patches 数量：", server.patches.size())
	
	
	
	print("\n[步骤 3] 版本比较...")
	var checker = UpdateChecker.new()
	var result = checker.check(local, server)
	print("  - 比较结果：", result)
	checker.queue_free()
	
	
	match result:
		"UP_TO_DATE":
			print("\n[结果] 已是最新版本，无需更新")
			update_state_changed.emit(InstallSignalHub.InstallState.UP_TO_DATE)
			
		"FULL_UPDATE_REQUIRED":
			print("\n[结果] 需要全量更新")
			server.force_full_package = true
			update_state_changed.emit(InstallSignalHub.InstallState.NEED_UPDATE)

		"NORMAL_UPDATE_REQUIRED":
			print("\n[结果] 需要补丁更新")
			update_state_changed.emit(InstallSignalHub.InstallState.NEED_UPDATE)
		_:
			print("\n[结果] 未知状态：", result)
			update_state_changed.emit(InstallSignalHub.InstallState.CHECK_FAILED)


func _on_hub_state_changed(state: InstallSignalHub.InstallState) -> void:
	update_state_changed.emit(state)
	match state:
		InstallSignalHub.InstallState.CHECKING_UPDATE:
			print("[InstallTestScene] 正在检查更新...")
		InstallSignalHub.InstallState.CHECK_FAILED:
			print("[InstallTestScene] 检查更新失败")
		InstallSignalHub.InstallState.UP_TO_DATE:
			print("[InstallTestScene] 已是最新版")
		InstallSignalHub.InstallState.DOWNLOAD_STARTED:
			print("[InstallTestScene] 开始下载...")
		InstallSignalHub.InstallState.DOWNLOAD_FINISHED:
			print("[InstallTestScene] 下载完成")
		InstallSignalHub.InstallState.INSTALL_STARTED:
			print("[InstallTestScene] 开始安装...")
		InstallSignalHub.InstallState.INSTALL_FINISHED:
			print("[InstallTestScene] 安装完成")


func _on_hub_error(error_message: String) -> void:
	update_error_occurred.emit(error_message)
	printerr("[InstallTestScene] 错误：", error_message)


func _on_下载_pressed() -> void:
	if not _server.force_full_package:
		update_flow.test_patch_download(_local,_server)
	else:
		update_flow.test_full_download(_local,_server)


func _on_选择自定义文件_pressed() -> void:
	var result = await update_choose_file.select_zip_file()
	
	if result:
		print("选择文件成功")
		await update_choose_file.copy_file_to_install(update_choose_file.selected_path)
	else:
		print("选择文件失败")
		update_error_occurred.emit("[InstallComponent]err: 选择文件失败")


func _on_开始安装_pressed() -> void:
	if not _server.force_full_package:
		update_flow.test_patch_install(_local,_server)
	else:
		if not update_choose_file.selected_path.is_empty():
			update_flow.test_full_install(_local,_server)
		else:
			update_error_occurred.emit("传递的自定义文件路径错误")
			printerr("传递的自定义文件路径错误")
