extends Node
##注意 这个export 我把它手动在编辑器里面添加 不知道会不会产生bug 希望不会
@export var repo_name :String = "ETN_Farm"
@export var update_choose_file: Node
@onready var uptate_type_control: Node = $Component/UptateTypeControl
@onready var update_flow: Node = $Component/UpdateFlow
@onready var update_ui_manager: Node = $Component/UpdateUiManager


var game_dir = OS.get_environment("APPDATA")
var user_path : String
##最小化修改 初始化 的时候 这些就会赋值 其他的就不用管了
var _local : VersionInfo
var _server : UpdatePolicy

signal update_needed_state_signal
signal update_process_state_signal

@export var update_needed_state : String = "UNKONW"
@export var update_process_state: String = "UNKONW"
@export var is_force_update : bool = false

func _ready() -> void:
	user_path = game_dir.path_join(repo_name)
	await init_check_version()
	#init_check_version()
	if _server.force_full_package:
		update_choose_file.copy_path ="user://download/full/"
	else:
		update_choose_file.copy_path ="user://download/patch/"
	

func init_check_version() -> void:
	print("========== 开始流程 ==========")
	print("用户目录: ", user_path)
	# 步骤1：获取本地版本信息
	print("\n[步骤1] 获取本地版本信息...")
	var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
	_local = local
	print("  - base_version: ", local.base_version)
	print("  - base_patch_max: ", local.base_patch_max)
	print("  - equal_version: ", local.equal_version)
	print("  - game_name: ", local.game_name)
	
	# 步骤2：获取服务器更新策略
	print("\n[步骤2] 获取服务器更新策略...")
	var server = await VersionUtils.get_update_policy(repo_name)
	_server=server
	if server.target_version == "":
		print("  [错误] 获取服务器策略失败")
		update_needed_state = "ERROR"
		update_needed_state_signal.emit(update_needed_state)
		return
	print("  - min_supported_version: ", server.min_supported_version)
	print("  - target_version: ", server.target_version)
	print("  - target_patch: ", server.target_patch)
	print("  - force_update: ", server.force_update)
	print("  - force_full_package: ", server.force_full_package)
	print("  - patches 数量: ", server.patches.size())
	
	is_force_update = server.force_update
	
	# 步骤3：版本比较
	print("\n[步骤3] 版本比较...")
	var checker = UpdateChecker.new()
	var result : String = checker.check(local, server)
	print("  - 比较结果: ", result)
	update_needed_state = result
	# 步骤4：根据结果执行操作
	update_needed_state_signal.emit(update_needed_state)
	match result:
		"UP_TO_DATE":
			print("\n[结果] 已是最新版本，无需更新")
		"FULL_UPDATE_REQUIRED":
			print("\n[结果] 需要全量更新")
			server.force_full_package = true
			#await test_full_install(local, server)
		"NORMAL_UPDATE_REQUIRED":
			print("\n[结果] 需要补丁更新")
			#await test_patch_install(local, server)
		_:
			print("\n[结果] 未知状态: ", result)




##注意 这个要等待哈
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
		# 检查是否选择了自定义文件
		if not update_choose_file.selected_path.is_empty():
			# 复制自定义文件到下载目录
			
			update_flow.test_full_install(_local,_server)
		else:
			printerr("传递的自定义文件路径错误")
