extends Node

signal status_changed(status: SetUpInfo.UpdateStatus, message: String)

# --- GitHub 仓库信息 ---
const GITHUB_OWNER = "GlacierXiaowei"
var REPO = "ETN_Launcher" # 启动器仓库 (根据需要修改)
# --- 文件与路径常量 ---
var ALLZIP = "all_upset.zip" # 全量更新的位置，用于在assets中查找
#var UPSETJSON = "upset.json"
var UPDATE_PATCH_PATH:String = "user://temp/download/update.zip"   # 下载的增量包
var UPDATE_ALL_PATH:String = ""   # 下载的更新包保存位置

# --- HTTPRequest 节点 ---
var update_checker: HTTPRequest # 检查版本 / 下载 setup.json
var file_downloader: HTTPRequest # 下载主程序 zip

# --- 内部状态变量 ---
var _current_status: SetUpInfo.UpdateStatus = SetUpInfo.UpdateStatus.IDLE:
	#set() 每当这个变量改变以后 就会执行下列的setter方法哦 免得信号或者回调
	set(value):
		if _current_status != value:
			_current_status = value
			#注意  get_status_message() 返回字符串
			var message = SetUpInfo.get_status_message(value)
			
			status_changed.emit(value, message)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# --- 初始化 HTTPRequest 节点 ---
	update_checker = HTTPRequest.new()
	file_downloader = HTTPRequest.new()
	add_child(update_checker)
	add_child(file_downloader)
	
	# --- 连接信号 ---
	update_checker.request_completed.connect(_on_release_check_completed)
	file_downloader.request_completed.connect(_on_download_completed)
	
	# --- 文件夹与初始状态 ---
	DirAccess.make_dir_absolute("user://temp/download")
	#初始化 
	_current_status = SetUpInfo.UpdateStatus.IDLE
	
	#初始化 下载地址
	init_update_exe_path("upset.zip")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func init_update_exe_path(filename: String):
	# 1. 获取系统原生 Downloads 目录（跨平台兼容）
	var system_download_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	# 2. 定义要保存的文件名
	
	# 3. String.path_join() 方法拼接完整路径
	UPDATE_ALL_PATH = system_download_dir.path_join(filename)
	print("更新文件将被保存到: ", UPDATE_ALL_PATH) # 增加一句打印，方便调试
	# 4. 【修正】使用 String.get_base_dir() 方法获取目录路径
	var download_dir: String = UPDATE_ALL_PATH.get_base_dir()
	# 5. 检查目录是否存在，不存在则创建
	if not DirAccess.dir_exists_absolute(download_dir):
		var error = DirAccess.make_dir_recursive_absolute(download_dir)
		if error != OK:
			WindowsManager.WindowsManager.show_simple_dialog("错误", "无法创建下载目录: " + download_dir)
	# 打印路径验证（调试用）
	print("UPDATE_ALL_PATH: ", UPDATE_ALL_PATH)

# UI 点击“检查更新”时调用此函数
func start_update_check():
	WindowsManager.show_simple_dialog("请稍后","正在从云端下载更新配置，请耐心等待窗口刷新。\n如果出现网络错误，可以先试试科学上网。")
	SetUpInfo.version_check_type="Launcher"
	if _current_status != SetUpInfo.UpdateStatus.IDLE and \
	   _current_status != SetUpInfo.UpdateStatus.UP_TO_DATE and \
	   _current_status != SetUpInfo.UpdateStatus.NEEDS_UPDATE and \
	   _current_status != SetUpInfo.UpdateStatus.INSTALL_COMPLETE and \
	 _current_status != SetUpInfo.UpdateStatus.FAIL_TO_CHECK and\
	_current_status != SetUpInfo.UpdateStatus.DOWNLOAD_FAILED and \
	_current_status != SetUpInfo.UpdateStatus.FAIL_TO_UNZIP:
		print("正在执行其他任务，请稍后...")
		WindowsManager.show_simple_dialog("请稍后", "已有还在运行的检查更新服务。")
		return
		
	match SetUpInfo.version_check_type:
		"Launcher":
			REPO = "ETN_Launcher"
			#EXECUTABLE = "ETN_Launcher.exe"
			
		"ETN":
			REPO = "ETN"
			#EXECUTABLE = "Embody The Now.exe"
	_current_status = SetUpInfo.UpdateStatus.CHECKING
	var url = "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_OWNER, REPO]
	
	# 发起第一个请求：获取 release 信息
	#回调成功 会进入更新回调函数 在下面
	var error = update_checker.request(url)
	if error != OK:
		_current_status = SetUpInfo.UpdateStatus.IDLE
		WindowsManager.show_simple_dialog("网络错误", "无法连接到更新服务器，请检查您的网络连接。")

# UI 点击“开始游戏”/“安装”/“更新”时调用此函数

# ======================================================================
# vvvvvvvvvvvvvvvv         更新流程回调函数         vvvvvvvvvvvvvvvvvv
# ======================================================================
# 第一个请求的回调：成功获取 Release 信息
func _on_release_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("检查更新失败", "无法获取版本信息 (错误码: %d)。" % response_code)
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("数据错误", "无法解析版本信息，请稍后再试。")
		return

	var release_data = json.get_data()
	# 在 assets 中寻找 setup.json
	var setup_json_url = _find_asset_url(release_data, "setup.json")
	
	if setup_json_url.is_empty():
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("配置错误", "在服务器上未找到 setup.json 配置文件。")
		return
		
	# 断开旧连接，准备发起第二个请求
	update_checker.request_completed.disconnect(_on_release_check_completed)
	update_checker.request_completed.connect(_on_setup_json_downloaded.bind(release_data))
	
	# 发起第二个请求：下载 setup.json 的内容
	update_checker.request(setup_json_url)

# 第二个请求的回调：成功下载并解析 setup.json
#注意 这已经是从release 中获取的自定义json
func _on_setup_json_downloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, release_data: Dictionary):
	# 用完后立刻断开连接
	update_checker.request_completed.disconnect(_on_setup_json_downloaded)
	# 重新连接上最初的回调，为下次检查做准备
	update_checker.request_completed.connect(_on_release_check_completed)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("配置下载失败", "无法获取 更新配置文件 文件 (错误码: %d)。" % response_code)
		return

	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("配置解析失败", "setup.json 文件格式错误。")
		return
	
	var remote_info = json.get_data()
	if not (remote_info.has("version") and remote_info.has("version_int") and remote_info.has("force_update")and remote_info.has("patch")):
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_CHECK
		WindowsManager.show_simple_dialog("配置内容缺失", "更新配置文件错误。")
		return
		
	var remote_version_int = remote_info["version_int"]
	var local_version_int = SetUpInfo.local_launcher_version_int if REPO=="ETN_Launcher" else SetUpInfo.local_game_version_int
	var version_min = remote_info["version_min"]

	var is_patch = remote_info["patch"]["is_patch"]
	var force_update =remote_info["force_update"]
	#SetUpInfo.patch= false re
	
	print("远程版本: %s, 本地版本: %s" % [remote_version_int, local_version_int])
	
	if remote_version_int > local_version_int:
		_current_status = SetUpInfo.UpdateStatus.NEEDS_UPDATE
		SetUpInfo.remote_version_info = remote_info # 保存远程版本信息
		
		var release_notes = release_data.get("body", "作者很懒，没有留下更新说明。")
		var release_title = release_data.get("tag_name", "未知版本号")
		var buttons_1 : Array[String] 
		if (force_update):
			buttons_1 =  ["全量更新"] if (is_patch and local_version_int>=version_min) else ["无缝更新","全量更新"]
		else:
			buttons_1 =  ["全量更新", "取消"] if (is_patch and local_version_int>=version_min) else ["无缝更新","全量更新", "取消"]
		var choice = await WindowsManager.show_dialog("发现新版本: %s" % release_title, release_notes, buttons_1)
		if choice != "取消":
			##SetUpInfo.patch=false if choice == "全量更新" else true
			#这里好像有点多余 ↑ 但是 后面 使用这个数据确认是否全量安装
			#↓ 注意 这只 针对启动器全量更新有效
			#下方目录为 系统的download文件夹
			if choice == "全量更新" : 
				init_update_exe_path("all_setup.zip")
				var download_url = _find_asset_url(release_data, ALLZIP, true) # 模糊匹配主程序
				#if SetUpInfo.patch:
					#_on_download_file_requested(download_url, UPDATE_PATCH_PATH)
				#else:
				_on_download_file_requested(download_url, UPDATE_ALL_PATH)
				
	else:
		_current_status = SetUpInfo.UpdateStatus.UP_TO_DATE
		WindowsManager.show_simple_dialog("欢迎","版本已经是最新")

# ======================================================================
# vvvvvvvvvvvvvvvv          下载与安装 (你的已有逻辑)          vvvvvvvvvvvvvvvvvv
# ======================================================================
# (你的函数) 开始文件下载
func _on_download_file_requested(url: String, save_path: String):
	clear_patch_download_folder("user://temp/download")
	_current_status = SetUpInfo.UpdateStatus.DOWNLOADING
	file_downloader.download_file = save_path
	var error = file_downloader.request(url)
	if error != OK:
		_on_download_completed(HTTPRequest.RESULT_CANT_CONNECT, -1, [], PackedByteArray())

# (你的函数，略作修改) 下载完成的回调
func _on_download_completed(result, _response_code, _headers, _body):
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "下载失败，请检查网络连接。"
		# (此处可保留你原有的详细错误匹配)
		WindowsManager.show_simple_dialog("下载失败", error_msg)
		_current_status = SetUpInfo.UpdateStatus.DOWNLOAD_FAILED
		return

	_current_status = SetUpInfo.UpdateStatus.UNZIPPING if SetUpInfo.version_check_type=="Game" or SetUpInfo.patch==true else SetUpInfo.UpdateStatus.INSTALL_COMPLETE 
	if _current_status == SetUpInfo.UpdateStatus.UNZIPPING:
		unzip_file(file_downloader.download_file)
	else:
		OS.shell_open(OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS))

# 1. 这是连接到你按钮点击信号的函数。它不再是 async。
func unzip_file(zip_path: String):
	# --- 准备工作 (这部分不变) ---
	var unzipper = ZIPReader.new()
	if unzipper.open(zip_path) != OK:
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_UNZIP
		WindowsManager.show_simple_dialog("解压失败", "无法打开更新包文件。")
		return

	var temp_unzip_dir = "user://temp/unzip"
	if DirAccess.dir_exists_absolute(temp_unzip_dir):
		DirAccess.remove_absolute(temp_unzip_dir)
	DirAccess.make_dir_absolute(temp_unzip_dir)

	var game_dir :String
	var files = unzipper.get_files()
	
	if SetUpInfo.version_check_type=="game" && SetUpInfo.patch==true :
		game_dir = "user://game/patch"
	if SetUpInfo.version_check_type=="Game" && SetUpInfo.patch==false :
		game_dir = "user://game/baoti"
	if SetUpInfo.version_check_type=="Launcher" && SetUpInfo.patch==true :
		game_dir = "user://patch"
		
	# --- 启动后台任务 ---
	var thread = Thread.new()

	# .bind() 创建一个任务包，这次我们把所有需要的变量都传进去
	var task = func(params):
		# vvvvvvvvvvvvvvvv 后台线程运行的代码 vvvvvvvvvvvvvvvv
		var result = {} # 线程内部的局部结果
		
		# --- 解压 ---
		for file_path in params.files:
			var file_dest_path = params.temp_dir.path_join(file_path)
			DirAccess.make_dir_recursive_absolute(file_dest_path.get_base_dir())
			var content = params.unzipper.read_file(file_path)
			var file = FileAccess.open(file_dest_path, FileAccess.WRITE)
			if file:
				file.store_buffer(content)
			else:
				result = {"success": false, "error_message": "无法写入临时文件: \n" + file_dest_path}
				# 【关键】后台线程用 call_deferred 安全地调用主线程的函数来报告结果
				_on_update_finished.call_deferred(result)
				# 清理并退出
				params.unzipper.close()
				DirAccess.remove_absolute(params.temp_dir)
				return
		params.unzipper.close()

		# --- 移动 ---
		if game_dir=="user://patch":
			var move_success = replace_folder_with_move(params.temp_dir, params.game_dir)
			if not move_success:
				result = {"success": false, "error_message": "无法安装。"}
				_on_update_finished.call_deferred(result)
				DirAccess.remove_absolute(params.temp_dir)
				return
		# --- 收尾 ---
		DirAccess.remove_absolute(params.zip_path)
		
		# --- 成功 ---
		result = {"success": true}
		_on_update_finished.call_deferred(result)
		# ^^^^^^^^^^^^^^^^ 后台线程代码结束 ^^^^^^^^^^^^^^^^
	
	# 把所有需要的变量打包成一个字典传递给线程
	var thread_params = {
		"unzipper": unzipper,
		"files": files,
		"temp_dir": temp_unzip_dir,
		"game_dir": game_dir,
		"zip_path": zip_path
	}
	
	# 启动线程，并把参数包传给它
	thread.start(task.bind(thread_params))
	# 这个 unzip_file 函数到这里就结束了，它不会等待，所以UI不会卡！
	print("后台更新任务已启动，主界面保持响应。")
# 2. 【新增】在你的脚本里添加这个全新的函数
# 这个函数只会在后台线程工作完毕后，被安全地调用
func _on_update_finished(result: Dictionary):
	print("后台任务完成，正在处理最终结果...")
	if result.success:
		# 更新版本号
		if SetUpInfo.version_check_type == "Launcher":
			SetUpInfo.local_launcher_version_str = SetUpInfo.remote_version_info.version
		else:
			SetUpInfo.local_game_version_str = SetUpInfo.remote_version_info.version
		
		# 弹窗提示成功
		_current_status = SetUpInfo.UpdateStatus.INSTALL_COMPLETE
		WindowsManager.show_simple_dialog("更新完成！", "游戏已成功更新至最新版本。")
	else:
		# 弹窗提示失败
		_current_status = SetUpInfo.UpdateStatus.FAIL_TO_UNZIP
		WindowsManager.show_simple_dialog("安装失败", result.error_message)

# 函数：替换文件夹 (强制移动)
# 作用：用 source_path 文件夹，强制替换掉 destination_path 文件夹。
func replace_folder_with_move(source_path: String, destination_path: String):
	if not DirAccess.dir_exists_absolute(source_path):
		print("操作失败: 源文件夹 '", source_path, "' 不存在。")
		return false # 返回失败
	var err
	if DirAccess.dir_exists_absolute(destination_path):
		print("目标文件夹 '", destination_path, "' 已存在，将执行删除操作。")
		err = DirAccess.remove_absolute(destination_path)
		if err != OK:
			print("操作失败: 删除旧文件夹 '", destination_path, "' 失败。")
			return false # 返回失败

	print("正在将 '", source_path, "' 移动到 '", destination_path, "'...")
	err = DirAccess.rename_absolute(source_path, destination_path)
	
	if err == OK:
		print("文件夹替换成功！")
		return true # 返回成功
	else:
		print("操作失败: 移动文件夹时发生错误。")
		return false # 返回失败

# ======================================================================
# vvvvvvvvvvvvvvvv            辅助与弹窗函数            vvvvvvvvvvvvvvvvvv
# ======================================================================
# 封装了你的弹窗逻辑，用于复杂的、需要等待用户选择的场景

# 在 Release 的 assets 中寻找特定文件的下载链接
func _find_asset_url(data: Dictionary, asset_name: String, fuzzy_match: bool = false) -> String:
	if not data.has("assets") or not data["assets"] is Array:
		return ""
		
	var target_name = asset_name.to_lower()
	for asset in data["assets"]:
		if asset is Dictionary:
			var current_name = asset.get("name", "").to_lower()
			var is_match = false
			if fuzzy_match:
				# 模糊匹配：以目标为开头，以 .zip 或 .exe 结尾
				is_match = current_name.begins_with(target_name.trim_suffix(".exe")) and \
						   (current_name.ends_with(".zip") or current_name.ends_with(".exe"))
			else:
				# 精确匹配
				is_match = (current_name == target_name)
			
			if is_match:
				return asset.get("browser_download_url", "")
	return ""

# 功能：清除指定文件夹内的所有文件（非递归，不删除子文件夹）
# 参数：folder_name - 在 user:// 目录下的文件夹名字，例如 "downloads"
func clear_patch_download_folder(dir_path:String):
	# 构造完整的文件夹路径
	#var dir_path = "user://temp/download"

	# 尝试打开这个目录
	var dir = DirAccess.open(dir_path)

	# 检查目录是否成功打开
	if dir:
		# 开始遍历目录中的内容
		dir.list_dir_begin()
		var file_name = dir.get_next()

		# 当 file_name 不为空字符串时，循环继续
		while file_name != "":
			# 忽略代表当前目录 "." 和上级目录 ".." 的特殊项
			if file_name != "." and file_name != "..":
				# 我们只删除文件，所以要判断一下它是不是一个目录
				if not dir.current_is_dir():
					# 删除文件，并打印日志用于调试
					var error = dir.remove(file_name)
					if error == OK:
						print("成功删除文件: ", dir_path.path_join(file_name))
					else:
						print("删除文件失败: ", dir_path.path_join(file_name))

			# 获取下一个文件/文件夹名
			file_name = dir.get_next()

	else:
		# 如果目录不存在或无法打开，打印错误信息
		print("错误: 无法打开或找不到目录: ", dir_path)
