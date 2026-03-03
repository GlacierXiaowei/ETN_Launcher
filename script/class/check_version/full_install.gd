extends PatchInstall
class_name FullInstall
#使用new之后 由于会使用httprequest 所以需要add_child才行



func _init(local: VersionInfo, server: UpdatePolicy) -> void:
	if local == null:
		push_error("[FullInstall] Error: local VersionInfo is null")
		error_occurred.emit("Initialization failed: local VersionInfo is null")
		return

	if server == null:
		push_error("[FullInstall] Error: server UpdatePolicy is null")
		error_occurred.emit("Initialization failed: server UpdatePolicy is null")
		return

	download_path = "user://download/full/"
	var appdata = OS.get_environment("APPDATA")
	var game_dir = appdata.path_join(server.game_name)
	install_path = game_dir.path_join("patch")
	DirAccess.make_dir_recursive_absolute(install_path)

	full_package = server.full_package
	target_patch = server.target_patch
	base_patch_max = local.base_patch_max
	all_patch = server.patches

func begin_download() -> void:
	is_download_successful = false
	state_changed.emit(InstallSignalHub.InstallState.DOWNLOAD_STARTED)

	if not clear_download_folder():
		push_error("[FullInstall] begin_download: Failed to clear download folder")
		error_occurred.emit("Failed to clear download folder")
		return

	if full_package.is_empty():
		push_error("[FullInstall] begin_download: full_package is empty")
		error_occurred.emit("Full package is empty")
		return

	var url = full_package.get("url", "")
	if url == "":
		push_error("[FullInstall] begin_download: URL is empty in full_package")
		error_occurred.emit("Full package URL is empty")
		return

	var file_name = "full_package.zip"
	download_single_file_with_shell(url, file_name)

func begin_install() -> void:
	is_install_successful = false
	state_changed.emit(InstallSignalHub.InstallState.INSTALL_STARTED)

	if download_path == "" or download_path.is_empty():
		push_error("[FullInstall] begin_install: download_path is empty")
		error_occurred.emit("Download path is empty")
		install_finished.emit(is_install_successful)
		return

	if install_path == "" or install_path.is_empty():
		push_error("[FullInstall] begin_install: install_path is empty")
		error_occurred.emit("Install path is empty")
		install_finished.emit(is_install_successful)
		return

	var zip_file = ""
	var download_dir = DirAccess.open(download_path)
	if download_dir == null:
		push_error("[FullInstall] begin_install: Failed to open download directory")
		error_occurred.emit("Failed to open download directory")
		install_finished.emit(is_install_successful)
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
		error_occurred.emit("No zip file found in download directory")
		install_finished.emit(is_install_successful)
		return

	var extracted_files = unzip_file(zip_file, download_path)
	if extracted_files.size() == 0:
		push_error("[FullInstall] begin_install: Failed to extract zip file")
		error_occurred.emit("Failed to extract zip file")
		install_finished.emit(is_install_successful)
		return

	var dir = DirAccess.open(download_path)
	if dir:
		dir.remove(zip_file)

	for extracted_file in extracted_files:
		var source_path = extracted_file
		var file_only_name = source_path.get_file()
		var dest_path = install_path.path_join(file_only_name)

		if FileAccess.file_exists(dest_path):
			var d = DirAccess.open(install_path)
			if d:
				d.remove(dest_path)

		if not move_file(source_path, dest_path):
			push_error("[FullInstall] begin_install: Failed to move file: " + file_only_name)
			error_occurred.emit("Failed to move file: " + file_only_name)
			install_finished.emit(is_install_successful)
			return

	is_install_successful = true
	state_changed.emit(InstallSignalHub.InstallState.INSTALL_FINISHED)
	install_finished.emit(is_install_successful)
##解压 zip 文件
func unzip_file(zip_path: String, dest_path: String) -> Array:
	var extracted_files = []

	if not FileAccess.file_exists(zip_path):
		push_error("[FullInstall] unzip_file: zip file does not exist: " + zip_path)
		error_occurred.emit("Zip file does not exist: " + zip_path)
		return extracted_files

	var zip_reader = ZIPReader.new()
	var error = zip_reader.open(zip_path)
	if error != OK:
		push_error("[FullInstall] unzip_file: Failed to open zip file, error: " + str(error))
		error_occurred.emit("Failed to open zip file: " + str(error))
		return extracted_files

	var files = zip_reader.get_files()

	for file in files:
		if file.ends_with("/"):
			continue

		var file_data = zip_reader.read_file(file)
		var dest_file_path = dest_path.path_join(file.get_file())

		var file_out = FileAccess.open(dest_file_path, FileAccess.WRITE)
		if file_out == null:
			push_error("[FullInstall] unzip_file: Failed to create file: " + dest_file_path)
			error_occurred.emit("Failed to create file: " + dest_file_path)
			continue

		file_out.store_buffer(file_data)
		file_out.close()
		extracted_files.append(dest_file_path)

	zip_reader.close()

	return extracted_files
