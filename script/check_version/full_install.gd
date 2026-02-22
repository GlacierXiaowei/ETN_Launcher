extends PatchInstall
class_name FullInstall



func _init(local: VersionInfo, server: UpdatePolicy) -> void:
	if local == null:
		push_error("[FullInstall] Error: local VersionInfo is null")
		return
	
	if server == null:
		push_error("[FullInstall] Error: server UpdatePolicy is null")
		return

	download_path = "user://download/full/"
	var appdata = OS.get_environment("APPDATA")
	var game_dir = appdata.path_join("ETN_Farm")
	install_path = game_dir.path_join("patch")
	DirAccess.make_dir_recursive_absolute(install_path)
	
	full_package = server.full_package
	target_patch = server.target_patch
	base_patch_max = local.base_patch_max
	all_patch = server.patches

func begin_download() -> void:
	is_download_successful = false
	
	# 步骤1：清空下载文件夹
	if not clear_download_folder():
		push_error("[FullInstall] begin_download: Failed to clear download folder")
		return
	
	# 步骤2：获取 full_package 的 URL
	if full_package.is_empty():
		push_error("[FullInstall] begin_download: full_package is empty")
		return
	
	var url = full_package.get("url", "")
	if url == "":
		push_error("[FullInstall] begin_download: URL is empty in full_package")
		return
	
	var file_name = "full_package.zip"
	
	# 步骤3：下载文件
	if not await download_single_file(url, file_name):
		push_error("[FullInstall] begin_download: Failed to download full package")
		return
	
	# 下载完成
	is_download_successful = true
	print("[FullInstall] begin_download: Full package downloaded successfully")

func begin_install() -> void:
	is_install_successful = false
	
	if download_path == "" or download_path.is_empty():
		push_error("[FullInstall] begin_install: download_path is empty")
		return
	
	if install_path == "" or install_path.is_empty():
		push_error("[FullInstall] begin_install: install_path is empty")
		return
	
	# 检查下载目录中是否有 zip 文件
	var zip_file = ""
	var download_dir = DirAccess.open(download_path)
	if download_dir == null:
		push_error("[FullInstall] begin_install: Failed to open download directory")
		return
	
	download_dir.list_dir_begin()
	var file_name = download_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".zip"):
			zip_file = download_path.path_join(file_name)
			break
		file_name = download_dir.get_next()
	download_dir.list_dir_end()
	
	if zip_file == "":
		push_error("[FullInstall] begin_install: No zip file found in download directory")
		return
	
	# 解压 zip 文件
	var extracted_files = unzip_file(zip_file, download_path)
	if extracted_files.size() == 0:
		push_error("[FullInstall] begin_install: Failed to extract zip file")
		return
	
	# 删除 zip 文件
	var dir = DirAccess.open(download_path)
	if dir:
		dir.remove(zip_file)
	
	# 清除 install_path 中与解压文件同名的文件，然后移动
	for extracted_file in extracted_files:
		var source_path = extracted_file
		var file_only_name = source_path.get_file()
		var dest_path = install_path.path_join(file_only_name)
		
		# 清除目标目录中同名的文件
		if FileAccess.file_exists(dest_path):
			var d = DirAccess.open(install_path)
			if d:
				d.remove(dest_path)
		
		# 移动文件
		if not move_file(source_path, dest_path):
			push_error("[FullInstall] begin_install: Failed to move file: " + file_only_name)
			return
	
	is_install_successful = true
	print("[FullInstall] begin_install: Full package installed successfully")

##解压 zip 文件
func unzip_file(zip_path: String, dest_path: String) -> Array:
	var extracted_files = []
	
	if not FileAccess.file_exists(zip_path):
		push_error("[FullInstall] unzip_file: zip file does not exist: " + zip_path)
		return extracted_files
	
	var zip_reader = ZIPReader.new()
	add_child(zip_reader)
	
	var error = zip_reader.open(zip_path)
	if error != OK:
		push_error("[FullInstall] unzip_file: Failed to open zip file")
		remove_child(zip_reader)
		zip_reader.free()
		return extracted_files
	
	var files = zip_reader.get_files()
	
	for file in files:
		# 跳过目录
		if file.ends_with("/"):
			continue
		
		var file_data = zip_reader.read_file(file)
		var dest_file_path = dest_path.path_join(file.get_file())
		
		var file_out = FileAccess.open(dest_file_path, FileAccess.WRITE)
		if file_out == null:
			push_error("[FullInstall] unzip_file: Failed to create file: " + dest_file_path)
			continue
		
		file_out.store_buffer(file_data)
		file_out.close()
		extracted_files.append(dest_file_path)
		print("[FullInstall] unzip_file: Extracted " + file.get_file())
	
	zip_reader.close()
	remove_child(zip_reader)
	zip_reader.free()
	
	return extracted_files
