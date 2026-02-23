extends Node

@export var install_test_scene : Node
var game_dir : String 
var user_path : String 
var installer 

func _ready() -> void:
	await get_tree().physics_frame
	game_dir = install_test_scene.game_dir
	user_path  = install_test_scene.user_path


##测试补丁安装
func test_patch_download(local, server) -> void:
	print("\n========== 开始补丁更新流程 ==========")
	
	# 创建补丁安装器
	installer = PatchInstall.new(local, server) as PatchInstall
	installer.install_path = user_path.path_join("patch")
	add_child(installer)
	
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
	await installer.download_finished
	
func test_patch_install(local, server) -> void:
	# 安装补丁
	installer = PatchInstall.new(local, server) as PatchInstall
	add_child(installer)
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
func test_full_download(local, server) -> void:
	print("\n========== 开始全量更新流程 ==========")
	
	# 创建完整包安装器
	installer  = FullInstall.new(local, server) as FullInstall
	add_child(installer)
	
	# 下载完整包
	print("[步骤1] 开始下载完整包...")
	installer.begin_download()
	
	##需要用户接管了
	
func test_full_install(local : VersionInfo, server : UpdatePolicy) -> void:
	# 安装完整包
	installer = FullInstall.new(local, server) as FullInstall
	add_child(installer)
	
	print("\n[步骤2] 开始安装完整包...")
	installer.begin_install()
	await installer.install_finished
	
	if not installer.is_install_successful:
		print("[错误] 完整包安装失败")
		installer.queue_free()
		return
	
	print("[成功] 完整包安装完成！")
	print("========== 全量更新流程结束 ==========")
	
	installer.queue_free()
