extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_website_meta_clicked(meta: Variant) -> void:
	var meta_str=str(meta)
	if meta_str=="glacier_xiaowei@163.com":
		DisplayServer.clipboard_set(meta_str)
		var button_text:Array[String]=["确定"]
		WindowsManager.show_dialog("提示","已经复制到剪贴板（否则请检查是否开启写入剪贴板权限）",button_text)
		pass
	else:
		OS.shell_open(meta_str)
		
	pass # Replace with function body.


func _on_thanks_meta_clicked(meta: Variant) -> void:
	var file_path = "res://assets/docs/version_introduction.txt"
	
	# 2. 调用我们自己编写的读取函数
	var file_content = read_text_from_file(file_path)
	
	# 3. 检查内容是否成功读取
	if file_content != "null":
		# 成功！现在 file_content 变量包含了文件的全部文本
		print("文件读取成功！")
		# 您可以把它赋给任何其他变量，比如一个 Label 的 text 属性
		# $MyLabel.text = file_content
	else:
		# 失败！文件不存在或无法读取
		print("读取文件失败：", file_path)

	
	
	if meta=="launcher":
		var alarm="该版本更新公告"
		
		var buttoon_text:Array[String]=["确定"]
		WindowsManager.show_dialog(alarm,file_content,buttoon_text)
	if meta=="ben_ti":
		WindowsManager.version_check(2)
	pass # Replace with function body.


# 一个健壮、可复用的文件读取函数
func read_text_from_file(path: String) -> String:
	# 检查文件是否存在，这是一个好习惯
	if not FileAccess.file_exists(path):
		printerr("错误：文件不存在于路径 \n", path)
		return "null"
	# 使用 FileAccess.open() 来打开文件
	# 第二个参数 FileAccess.READ 表示我们只想读取文件
	var file = FileAccess.open(path, FileAccess.READ)
	# 检查文件是否成功打开
	if file == null:
		# 如果打开失败，FileAccess.get_open_error() 会返回错误码
		printerr("打开文件时发生错误: \n", FileAccess.get_open_error())
		return "null"
	# 使用 get_as_text() 一次性读取整个文件的文本内容
	var content = file.get_as_text()
	# **至关重要的一步**：关闭文件！
	# 这会释放文件句柄，防止内存泄漏和文件被锁定的问题
	file.close()
	return content
