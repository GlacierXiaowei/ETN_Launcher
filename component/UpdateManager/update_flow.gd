extends Node

@export var install_test_scene : Node
@export var signal_hub : InstallSignalHub
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
	
	installer = PatchInstall.new(local, server) as PatchInstall
	installer.install_path = user_path.path_join("patch")
	add_child(installer)
	
	if signal_hub:
		signal_hub.register_installer(installer)
	
	installer.all_patch = server.patches
	print("[步骤 1] 已设置 all_patch: ", installer.all_patch.size(), " 个补丁")
	
	installer.init_installed_patch()
	print("[步骤 2] 已安装补丁：", installer.installed_patch)
	
	installer.init_need_installed_patch()
	print("[步骤 3] 需要下载的补丁：", installer.need_installed_patch)
	
	print("\n[步骤 4] 开始下载补丁...")
	installer.begin_download()
	await installer.download_finished
	
	if signal_hub:
		signal_hub.unregister_installer(installer)
	
func test_patch_install(local, server) -> void:
	installer = PatchInstall.new(local, server) as PatchInstall
	add_child(installer)
	
	if signal_hub:
		signal_hub.register_installer(installer)
	
	print("\n[步骤 5] 开始安装补丁...")
	installer.begin_install()
	await installer.install_finished
	
	if signal_hub:
		signal_hub.unregister_installer(installer)
	
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
	
	installer = FullInstall.new(local, server) as FullInstall
	add_child(installer)
	
	if signal_hub:
		signal_hub.register_installer(installer)
	
	print("[步骤 1] 开始下载完整包...")
	installer.begin_download()
	
func test_full_install(local : VersionInfo, server : UpdatePolicy) -> void:
	installer = FullInstall.new(local, server) as FullInstall
	add_child(installer)
	
	if signal_hub:
		signal_hub.register_installer(installer)
	
	print("\n[步骤 2] 开始安装完整包...")
	installer.begin_install()
	await installer.install_finished
	
	if signal_hub:
		signal_hub.unregister_installer(installer)
	
	if not installer.is_install_successful:
		print("[错误] 完整包安装失败")
		installer.queue_free()
		return
	
	print("[成功] 完整包安装完成！")
	print("========== 全量更新流程结束 ==========")
	
	installer.queue_free()
