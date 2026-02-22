extends Control

var game_dir = OS.get_environment("APPDATA")
var user_path = game_dir.path_join("ETN_Farm")

func _ready() -> void:
	print("========== 开始测试流程 ==========")
	print("用户目录: ", user_path)
	test_full_flow()


@onready var label: Label = $MarginContainer/VBoxContainer/Label
func test_full_flow() -> void:
	# 步骤1：获取本地版本信息
	print("\n[步骤1] 获取本地版本信息...")
	var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
	print("  - base_version: ", local.base_version)
	print("  - base_patch_max: ", local.base_patch_max)
	print("  - equal_version: ", local.equal_version)
	print("  - game_name: ", local.game_name)
	
	# 步骤2：获取服务器更新策略
	print("\n[步骤2] 获取服务器更新策略...")
	var server = await VersionUtils.get_update_policy("ETN_Farm")
	if server.target_version == "":
		print("  [错误] 获取服务器策略失败")
		return
	print("  - min_supported_version: ", server.min_supported_version)
	print("  - target_version: ", server.target_version)
	print("  - target_patch: ", server.target_patch)
	print("  - force_update: ", server.force_update)
	print("  - force_full_package: ", server.force_full_package)
	print("  - patches 数量: ", server.patches.size())
	
	# 步骤3：版本比较
	print("\n[步骤3] 版本比较...")
	var checker = UpdateChecker.new()
	var result = checker.check(local, server)
	print("  - 比较结果: ", result)
	
	# 步骤4：根据结果执行操作
	match result:
		"UP_TO_DATE":
			print("\n[结果] 已是最新版本，无需更新")
		"FULL_UPDATE_REQUIRED":
			print("\n[结果] 需要全量更新")
			await test_full_install(local, server)
		"NORMAL_UPDATE_REQUIRED":
			print("\n[结果] 需要补丁更新")
			await test_patch_install(local, server)
		_:
			print("\n[结果] 未知状态: ", result)

##测试补丁安装
func test_patch_install(local, server) -> void:
	print("\n========== 开始补丁更新流程 ==========")
	
	# 创建补丁安装器
	var installer = PatchInstall.new(local, server)
	installer.install_path = user_path.path_join("patch")
	add_child(installer)
	
	# 连接进度信号
	installer.download_progress_changed.connect(_on_patch_download_progress)
	
	# 设置服务器补丁列表
	installer.all_patch = server.patches
	print("[步骤1] 已设置 all_patch: ", installer.all_patch.size(), " 个补丁")
	
	# 扫描已安装补丁
	installer.init_installed_patch()
	print("[步骤2] 已安装补丁: ", installer.installed_patch)
	
	# 计算需要下载的补丁
	installer.init_need_installed_patch()
	print("[步骤3] 需要下载的补丁: ", installer.need_installed_patch)
	
	if installer.need_installed_patch.size() == 0:
		print("[提示] 没有需要下载的补丁")
		installer.queue_free()
		return
	
	# 下载补丁
	print("\n[步骤4] 开始下载补丁...")
	await installer.begin_download()
	
	if not installer.is_download_successful:
		print("[错误] 补丁下载失败")
		installer.queue_free()
		return
	
	print("[成功] 补丁下载完成")
	
	# 安装补丁
	print("\n[步骤5] 开始安装补丁...")
	installer.begin_install()
	
	if not installer.is_install_successful:
		print("[错误] 补丁安装失败")
		installer.queue_free()
		return
	
	print("[成功] 补丁安装完成！")
	print("========== 补丁更新流程结束 ==========")
	
	installer.queue_free()

##测试完整包安装
func test_full_install(local, server) -> void:
	print("\n========== 开始全量更新流程 ==========")
	
	# 创建完整包安装器
	var installer = FullInstall.new(local, server)
	add_child(installer)
	
	# 连接进度信号
	installer.download_progress_changed.connect(_on_full_download_progress)
	
	# 下载完整包
	print("[步骤1] 开始下载完整包...")
	await installer.begin_download()
	
	if not installer.is_download_successful:
		print("[错误] 完整包下载失败")
		installer.queue_free()
		return
	
	print("[成功] 完整包下载完成")
	
	# 安装完整包
	print("\n[步骤2] 开始安装完整包...")
	installer.begin_install()
	
	if not installer.is_install_successful:
		print("[错误] 完整包安装失败")
		installer.queue_free()
		return
	
	print("[成功] 完整包安装完成！")
	print("========== 全量更新流程结束 ==========")
	
	installer.queue_free()

##补丁下载进度回调
func _on_patch_download_progress(current: int, total: int):
	var progress = 0.0
	if total > 0:
		progress = float(current) / float(total) * 100.0
	print("[补丁下载进度] %d / %d (%.1f%%)" % [current, total, progress])
	if label:
		label.text = "[补丁下载] %d / %d (%.1f%%)" % [current, total, progress]

##完整包下载进度回调
func _on_full_download_progress(current: int, total: int):
	var progress = 0.0
	if total > 0:
		progress = float(current) / float(total) * 100.0
	print("[完整包下载进度] %d / %d (%.1f%%)" % [current, total, progress])
	if label:
		label.text = "[完整包下载] %d / %d (%.1f%%)" % [current, total, progress]
