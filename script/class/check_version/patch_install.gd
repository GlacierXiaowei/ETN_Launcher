extends Node
class_name PatchInstall
#使用new之后 由于会使用httprequest 所以需要add_child才行

var full_package : Dictionary
var all_patch: Array = []

var needed_patch: Array = []

var installed_patch: Array = []
var download_path: String = "user://download/patch/"
var need_installed_patch: Array = []

var target_patch: int
var base_patch_max: int

##初始化需要传值
var install_path: String

#成功的标志
var is_download_successful : bool = false
var is_install_successful : bool = false

signal install_finished


func _init(local: VersionInfo, server: UpdatePolicy) -> void:
	if local == null:
		push_error("[PatchInstall] Error: local VersionInfo is null")
		return
	
	if server == null:
		push_error("[PatchInstall] Error: server UpdatePolicy is null")
		return


	all_patch = server.patches
	target_patch = server.target_patch
	base_patch_max = local.base_patch_max
	var appdata = OS.get_environment("APPDATA")
	var game_dir = appdata.path_join(server.game_name)
	install_path = game_dir.path_join("patch")
	DirAccess.make_dir_recursive_absolute(install_path)
	#full_package = server.full_package

func init_installed_patch() -> void:
	installed_patch.clear()
	
	if install_path == "" or install_path.is_empty():
		push_error("[PatchInstall] Error: install_path is empty")
		return
	
	if not DirAccess.dir_exists_absolute(install_path):
		push_error("[PatchInstall] Error: Directory does not exist: " + install_path)
		return
	
	var dir = DirAccess.open(install_path)
	if dir == null:
		push_error("[PatchInstall] Error: Failed to open directory: " + install_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("Patch_") and file_name.ends_with(".pck"):
			var number_str = file_name.trim_prefix("Patch_").trim_suffix(".pck")
			var number = number_str.to_int()
			if number > 0:
				installed_patch.append(number)
		file_name = dir.get_next()
	dir.list_dir_end()
	installed_patch.sort()

func init_need_installed_patch() -> void:
	need_installed_patch.clear()
	
	if base_patch_max < 0:
		push_error("[PatchInstall] Error: base_patch_max is invalid: " + str(base_patch_max))
		return
	
	if target_patch < 0:
		push_error("[PatchInstall] Error: target_patch is invalid: " + str(target_patch))
		return
	
	if base_patch_max > target_patch:
		push_error("[PatchInstall] Error: base_patch_max (" + str(base_patch_max) + ") is greater than target_patch (" + str(target_patch) + ")")
		return
	
	for i in range(base_patch_max + 1, target_patch + 1):
		if not i in installed_patch:
			need_installed_patch.append(i)

##开始下载补丁
func begin_download() -> void:
	is_download_successful = false
	
	# 步骤 1：清空下载文件夹
	if not VersionUtils.clear_folder(download_path):
		push_error("[PatchInstall] begin_download: Failed to clear download folder")
		return
	
	# 步骤 2：获取需要下载的 URL 列表
	var urls = get_patch_urls()
	if urls.size() == 0:
		push_error("[PatchInstall] begin_download: No URLs found for needed patches")
		return
	
	# 步骤 3：依次下载每个文件
	for url_info in urls:
		if not await download_single_file(url_info.url, url_info.file_name):
			push_error("[PatchInstall] begin_download: Failed to download " + url_info.file_name)
			return
	
	is_download_successful = true
	print("[PatchInstall] begin_download: All patches downloaded successfully")


##清空下载文件夹
func clear_download_folder() -> bool:
	if download_path == "" or download_path.is_empty():
		push_error("[PatchInstall] clear_download_folder: download_path is empty")
		return false
	
	# 如果目录不存在，则创建
	if not DirAccess.dir_exists_absolute(download_path):
		var d = DirAccess.open("user://")
		if d == null:
			push_error("[PatchInstall] clear_download_folder: Failed to open user://")
			return false
		var err = d.make_dir_recursive(download_path)
		if err != OK:
			push_error("[PatchInstall] clear_download_folder: Failed to create directory")
			return false
		return true
	
	# 目录已存在，清空其中所有文件
	var dir = DirAccess.open(download_path)
	if dir == null:
		push_error("[PatchInstall] clear_download_folder: Failed to open download directory")
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = download_path.path_join(file_name)
			var err = dir.remove(full_path)
			if err != OK:
				push_error("[PatchInstall] clear_download_folder: Failed to delete file: " + full_path)
				dir.list_dir_end()
				return false
		file_name = dir.get_next()
	dir.list_dir_end()
	return true

##根据need_installed_patch获取对应的URL列表
func get_patch_urls() -> Array:
	var result = []
	
	if all_patch.size() == 0:
		push_error("[PatchInstall] get_patch_urls: all_patch is empty")
		return result
	
	for patch_id in need_installed_patch:
		var found = false
		for patch in all_patch:
			if patch.get("patch_id") == patch_id:
				var url = patch.get("url", "")
				if url == "":
					push_error("[PatchInstall] get_patch_urls: URL is empty for patch_id: " + str(patch_id))
					found = true
					break
				var file_name = "Patch_" + str(patch_id).pad_zeros(3) + ".pck"
				result.append({"url": url, "file_name": file_name, "patch_id": patch_id})
				found = true
				break
		
		if not found:
			push_error("[PatchInstall] get_patch_urls: Cannot find patch_id: " + str(patch_id) + " in all_patch")
	
	return result

##下载单个文件
func download_single_file(url: String, file_name: String) -> bool:
	if url == "" or url.is_empty():
		push_error("[PatchInstall] download_single_file: URL is empty")
		return false
	
	if file_name == "" or file_name.is_empty():
		push_error("[PatchInstall] download_single_file: file_name is empty")
		return false
	
	# 创建HTTP请求节点
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var download_success = false
	var error_message = ""
	
	# 发送请求
	var error = http_request.request(url)
	if error != OK:
		push_error("[PatchInstall] download_single_file: Request failed with error: " + str(error))
		remove_child(http_request)
		http_request.queue_free()
		return false
	
	# 等待请求完成并获取结果
	var result = await http_request.request_completed
	
	# 处理结果
	var response_code = result[1]
	if response_code == 200:
		var body = result[3]
		var save_path = download_path.path_join(file_name)
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file == null:
			error_message = "Failed to create file: " + save_path
			download_success = false
		else:
			file.store_buffer(body)
			file.close()
			download_success = true
			print("[PatchInstall] download_single_file: Downloaded " + file_name)
	else:
		error_message = "HTTP error: " + str(response_code)
		download_success = false
	
	# 清理
	remove_child(http_request)
	http_request.queue_free()
	
	if not download_success:
		push_error("[PatchInstall] download_single_file: " + error_message)
	
	return download_success

##使用系统浏览器下载
func download_single_file_with_shell(url: String, file_name: String) -> bool:
	if url.is_empty() or file_name.is_empty():
		push_error("Invalid url or file_name")
		return false

	print("[PatchInstall] Opening browser to download: ", url)
	print("[PatchInstall] Please save the file to: ", download_path)
	OS.shell_open(url)
	
	return true

##开始安装补丁
func begin_install() -> void:
	is_install_successful = false
	
	if download_path == "" or download_path.is_empty():
		push_error("[PatchInstall] begin_install: download_path is empty")
		install_finished.emit(is_install_successful)
		return
	
	if install_path == "" or install_path.is_empty():
		push_error("[PatchInstall] begin_install: install_path is empty")
		install_finished.emit(is_install_successful)
		return
	
	# 检查下载目录是否存在
	if not DirAccess.dir_exists_absolute(download_path):
		push_error("[PatchInstall] begin_install: Download directory does not exist: " + download_path)
		install_finished.emit(is_install_successful)
		return
	
	# 检查安装目录是否存在，如果不存在则创建
	if not DirAccess.dir_exists_absolute(install_path):
		var d = DirAccess.open("user://")
		if d == null:
			push_error("[PatchInstall] begin_install: Failed to open user://")
			install_finished.emit(is_install_successful)
			return
		var err = d.make_dir_recursive(install_path)
		if err != OK:
			push_error("[PatchInstall] begin_install: Failed to create install directory")
			install_finished.emit(is_install_successful)
			return
	
	# 获取下载目录中的所有文件
	var download_dir = DirAccess.open(download_path)
	if download_dir == null:
		push_error("[PatchInstall] begin_install: Failed to open download directory")
		install_finished.emit(is_install_successful)
		return
	
	var files_to_move = []
	download_dir.list_dir_begin()
	var file_name = download_dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			files_to_move.append(file_name)
		file_name = download_dir.get_next()
	download_dir.list_dir_end()
	
	if files_to_move.size() == 0:
		push_error("[PatchInstall] begin_install: No files to install")
		install_finished.emit(is_install_successful)
		return
	
	# 移动每个文件
	for f in files_to_move:
		var source_path = download_path.path_join(f)
		var dest_path = install_path.path_join(f)
		
		if not move_file(source_path, dest_path):
			push_error("[PatchInstall] begin_install: Failed to move file: " + f)
			install_finished.emit(is_install_successful)
			return
	
	is_install_successful = true
	print("[PatchInstall] begin_install: All patches installed successfully")
	install_finished.emit(is_install_successful)

##移动单个文件
func move_file(source: String, dest: String) -> bool:
	if source == "" or source.is_empty():
		push_error("[PatchInstall] move_file: source path is empty")
		return false
	
	if dest == "" or dest.is_empty():
		push_error("[PatchInstall] move_file: dest path is empty")
		return false
	
	# 使用DirAccess移动文件
	var dir = DirAccess.open(source.get_base_dir())
	if dir == null:
		push_error("[PatchInstall] move_file: Failed to open source directory")
		return false
	
	var error = dir.rename(source, dest)
	if error != OK:
		push_error("[PatchInstall] move_file: Failed to rename file from " + source + " to " + dest)
		return false
	
	print("[PatchInstall] move_file: Moved " + source.get_file() + " to " + dest)
	return true
