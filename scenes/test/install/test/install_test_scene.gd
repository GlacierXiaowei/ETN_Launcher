extends Node
@export var update_choose_file: Node

@export var game_name : String = "ETN_Farm"

@onready var uptate_type_control: Node = $Component/UptateTypeControl
@onready var update_flow: Node = $Component/UpdateFlow
@onready var update_ui_manager: Node = $Component/UpdateUiManager
@onready var signal_hub: Node = $Component/InstallSignalHub

var game_dir = OS.get_environment("APPDATA")
var user_path = game_dir.path_join(game_name)
var _local : VersionInfo
var _server : UpdatePolicy

signal update_needed(result: String)
signal up_to_date
signal update_state_changed(state: InstallSignalHub.InstallState)
signal update_error_occurred(error_message: String)


func _ready() -> void:
	if signal_hub:
		signal_hub.state_changed.connect(_on_hub_state_changed)
		signal_hub.error_occurred.connect(_on_hub_error)
	
	await init_check_version()
	if _server.force_full_package:
		update_choose_file.copy_path ="user://download/full/"
	else:
		update_choose_file.copy_path ="user://download/patch/"


func init_check_version() -> void:
	update_state_changed.emit(InstallSignalHub.InstallState.CHECKING_UPDATE)
	print("========== 开始测试流程 ==========")
	print("用户目录：", user_path)
	print("\n[步骤 1] 获取本地版本信息...")
	var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
	_local = local
	print("  - base_version: ", local.base_version)
	print("  - base_patch_max: ", local.base_patch_max)
	print("  - equal_version: ", local.equal_version)
	print("  - game_name: ", local.game_name)
	
	print("\n[步骤 2] 获取服务器更新策略...")
	var server = await VersionUtils.get_update_policy("ETN_Farm")
	_server=server
	if server.target_version == "":
		print("  [错误] 获取服务器策略失败")
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
			up_to_date.emit()
		"FULL_UPDATE_REQUIRED":
			print("\n[结果] 需要全量更新")
			server.force_full_package = true
			update_needed.emit(result)
		"NORMAL_UPDATE_REQUIRED":
			print("\n[结果] 需要补丁更新")
			update_needed.emit(result)
		_:
			print("\n[结果] 未知状态：", result)
			update_needed.emit(result)


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


func _on_开始安装_pressed() -> void:
	if not _server.force_full_package:
		update_flow.test_patch_install(_local,_server)
	else:
		if not update_choose_file.selected_path.is_empty():
			update_flow.test_full_install(_local,_server)
		else:
			printerr("传递的自定义文件路径错误")
