extends Node

@onready var install_component: InstallComponent
@export var copy_path : String =""
var selected_path :String

signal input_finished


func _ready() -> void:
	await  get_tree().process_frame
	install_component = $"../.."


func select_zip_file(path_mode : bool = false) -> bool:
	selected_path = ""
	if path_mode:
		_on_输入路径_pressed()
		await input_finished
		if selected_path.is_empty():
			print("选择自定义安装包失败")
			return false
		if not is_valid_form(selected_path):
			print("选择自定义安装包失败")
			return false
		
		print("选择自定义安装包成功")
		return true
		#selected_path = path 上述函数输入路径必须正常才能够返回true 同时成功之后也会返回true
	var file_dialog := FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.zip,*.pck")
	add_child(file_dialog)

	
	file_dialog.popup_centered()

	var path = await file_dialog.file_selected
	selected_path = path

	file_dialog.queue_free()

	if selected_path.is_empty():
		return false
	if not is_valid_form(selected_path):
		return false

	print("选择自定义安装包成功")
	return true


func _on_输入路径_pressed() -> void:
	PopupManager.show_input(
		"输入文件路径",
		"请在下列的输入框中输入文件的完整路径...
请不要有双引号等等，实例:\n  D://下载(D)//ETN_Farm.zip",
		"请在此输入...",
		_on_path_confirm,
		func(): install_component.update_state_changed.emit(InstallSignalHub.InstallState.DOWNLOAD_FINISHED),
		""
	)


func _on_path_confirm(input_path: String) -> void:
	if input_path.is_empty():
		printerr("路径不能为空")
		PopupManager.show_alert("错误","路径不能为空",_on_输入路径_pressed)
		return
	
	if not FileAccess.file_exists(input_path):
		printerr("文件不存在：" + input_path)
		PopupManager.show_alert("错误","文件不存在：" + input_path,_on_输入路径_pressed)
		return
	
	#if not input_path.ends_with(".zip"):
		#printerr("请选择 ZIP 文件")
		#PopupManager.show_alert("错误","路径不能为空",_on_输入路径_pressed)
		#return
	
	selected_path = input_path
	print("路径输入成功：", input_path)
	input_finished.emit()
	###由于回调太麻烦了 所以这里直接就复制了
	#copy_file_to_install(input_path)


func is_valid_form(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	
	if file.get_length() < 4:
		file.close()
		return false
	
	var bytes = file.get_buffer(4)
	file.close()
	var is_zip = bytes[0] == 0x50 and bytes[1] == 0x4B
	var is_pck = bytes[0] == 0x47 and bytes[1] == 0x44 and bytes[2] == 0x4F and bytes[3] == 0x54
	
	return is_zip or is_pck


##为了避免客户端的卡顿 该函数将在按下安装键之后 再调用
##这个path 就是咱们原本D盘的那个位置
func copy_file_to_install(source_path: String) -> bool:
	VersionUtils.clear_folder(selected_path)
	if source_path.is_empty():
		push_error("Source path empty")
		return false

	if not FileAccess.file_exists(source_path):
		push_error("Source file does not exist")
		return false

	var file_name = source_path.get_file()
	var dest_path = copy_path.path_join(file_name)

	DirAccess.make_dir_recursive_absolute(copy_path)

	var src = FileAccess.open(source_path, FileAccess.READ)
	if src == null:
		push_error("Failed to open source file")
		return false

	var dst = FileAccess.open(dest_path, FileAccess.WRITE)
	if dst == null:
		push_error("Failed to create destination file")
		src.close()
		return false

	var buffer_size = 1024 * 1024  # 1MB
	while not src.eof_reached():
		var chunk = src.get_buffer(buffer_size)
		dst.store_buffer(chunk)

	src.close()
	dst.close()

	print("File copied to:", dest_path)
	return true
