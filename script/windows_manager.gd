extends CanvasLayer

# ======================================================================
# vvvvvvvvv               配置区 (请在此处修改)               vvvvvvvvv
# ======================================================================
# --- GitHub 仓库信息 ---
const GITHUB_OWNER = "GlacierXiaowei"

# !! 重要：每次您打包新版本时，都需要在这里更新当前版本号 !!
const CURRENT_VERSION ="v1.0.0.2"
# 与您的 GitHub Release Tag 保持一致(请在函数中修改)

# --- 游戏可执行文件名 ---
#在函数里面 定义并修改
#const EXECUTABLE_NAME_1 = "ETN_Launcher.exe"
#const EXECUTABLE_NAME_2 = "ETN.exe"
# ======================================================================
# vvvvvvvvv               节点引用 (无需修改)                 vvvvvvvvv
# ======================================================================
# 确保您的主场景中包含以下节点，并已设置为唯一名称 (%)
@onready var release_request: HTTPRequest = %ReleaseRequest
# --- 内部变量 (无需修改) ---
var new_version_download_url: String = ""
var LATEST_RELEASE_URL: String


# 1. 在脚本顶部声明一个成员变量，初始为 null
var current_windows = null 


var windows_preload = preload("res://scenes/windows.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func show_dialog(alarm_texts: String,detail_texts: String, button_texts: Array[String]) ->String:
	current_windows=windows_preload.instantiate()
	add_child(current_windows)
	# 2. 【最终修改】设置它的尺寸为固定的 1080x1920
	current_windows.size = Vector2(1920, 1080)
	
	
	
	current_windows.show_dialog(alarm_texts,detail_texts, button_texts)
	#show_dialog(alarm_texts: String,detail_texts: String, button_texts: Array[String])-> void:
	var result= await current_windows.complete
	return result

func version_check(type: int) ->void:
	var EXECUTABLE_NAME= "ETN_Launcher.exe"
	var GITHUB_REPO = "ETN_Launcher"
	
	var detail="正在从github获取更新......
使用最新版本的程序是一个好习惯哦
请确保科学上网
请等待该窗口刷新"
	var button_text:Array[String]=["取消"]
	WindowsManager.show_dialog("请稍后",detail, button_text)
	
	#1是 启动器   
	#2是 游戏包题
	if type==1:
		EXECUTABLE_NAME= "ETN_Launcher.exe"
		GITHUB_REPO = "ETN_Launcher"
		pass
		#启动器
	
	
	if type==2:
		EXECUTABLE_NAME= "ETN.exe"
		GITHUB_REPO = "ETN"
		pass
	
	# 1. 修正点：在运行时初始化 URL，避免 const 错误
	LATEST_RELEASE_URL = "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_OWNER, GITHUB_REPO]
	
	# 2. 整合点：连接网络请求完成的信号
	release_request.request_completed.connect(_on_release_request_completed.bind(EXECUTABLE_NAME))
	
	var error = release_request.request(LATEST_RELEASE_URL)
	
	# 2. 如果请求本身就失败了（比如没网络）
	if error != OK:
		#var windows=windows_preload.instantiate()
		#add_child(windows)
		## 2. 【最终修改】设置它的尺寸为固定的 1080x1920
		#windows.size = Vector2(1920, 1080)
		
		# HTTPRequest.Result.RESULT_SUCCESS 是 Godot 内置的常量，值为 0
		if error != HTTPRequest.Result.RESULT_SUCCESS:
			var button_text_2:Array[String] = ["确定"]
			# result 不为 SUCCESS，意味着是连接超时、DNS解析失败等网络层面的问题
			await show_dialog("网络错误", "无法连接到更新服务器，请检查您的网络连接。", button_text_2)
			return # 关键：处理完后立刻退出函数
		
		var button_text_1:Array[String]=["确定"]
		await show_dialog("游戏BUG", "HTTPRequest游戏内置节点出现错误，请联系开发者或者尝试 设置->修复游戏",button_text_1)
		return
		
	
	# 3. 等待 _on_release_request_completed 信号被触发
	# 该函数会在信号触发后，根据结果填充 new_version_download_url 变量
	await release_request.request_completed
	# 4. 在 _on_release_request_completed 执行完毕后，继续这里的逻辑
	# 此时所有需要显示的信息都已经准备好了
	# (具体显示的逻辑已移至 _on_release_request_completed 中)

func _on_release_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray,EXECUTABLE_NAME:String) -> void:
	
	
	
	
	# Case 1: 网络请求成功，但服务器返回错误 (例如 404 Not Found)
	if response_code != 200:
		var button_text_0:Array[String]=["取消"]
		await show_dialog("检查更新失败", "无法获取版本信息 (错误码: %d)。" % response_code,button_text_0 )
		return
# Case 2: JSON 解析失败
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		var button_text_0:Array[String]=["请尝试联系开发者解决"]
		await show_dialog("数据错误", "无法解析版本信息，请稍后再试。", button_text_0)
		return
# Case 3: 成功获取并解析 JSON 数据
	var release_data = json.get_data()
	var latest_tag = release_data.get("tag_name", "")
	# Case 3.1: JSON 数据中没有版本号
	if latest_tag.is_empty():
		var button_text_0:Array[String]=["请尝试联系开发者解决"]
		await show_dialog("信息缺失", "无法在版本数据中找到版本号。", button_text_0)
		return
	print("当前版本: %s, 最新版本: %s" % [CURRENT_VERSION, latest_tag])

# Case 3.2: 当前已是最新版本
	if latest_tag == CURRENT_VERSION:
		var button_text_1:Array[String]=["确定"]
		await show_dialog("欢迎", "您的游戏已是最新版本！", button_text_1)
		
	# Case 3.3: 发现新版本
	else:
		var release_title = release_data.get("name", "发现新内容")
		var release_body = release_data.get("body", "作者很懒，没有留下更新说明。")
		var dialog_detail = "[color=yellow]%s[/color]\n\n%s" % [release_title, release_body] # 使用 BBCode
		
		# 寻找下载链接
		new_version_download_url = _find_download_url(release_data,EXECUTABLE_NAME)
		
		var user_choice: String
		if not new_version_download_url.is_empty():
			# 如果找到了下载链接，提供下载选项
			var button_text_2:Array[String]=["立即下载", "取消"]
			user_choice = await show_dialog("发现新版本: " + latest_tag, dialog_detail, button_text_2)
			if user_choice == "立即下载":
				OS.shell_open(new_version_download_url)
				#OS.shell_open("C:/Users/name/Downloads")
				return
		else:
			# 如果没找到下载链接，只提供提示
			var button_text_2:Array[String]=["确定","请联系开发者"]
			user_choice = await show_dialog("发现新版本 (无下载链接)", dialog_detail,button_text_2 )
			
# 从 Release 数据中寻找 .exe 文件的下载链接
# 从 Release 数据中寻找 .exe 文件的下载链接
# 从 Release 数据中寻找 .exe 文件的下载链接 (智能匹配版)
func _find_download_url(data: Dictionary, EXECUTABLE_NAME: String) -> String:
	if data.has("assets") and data["assets"] is Array:
		
		# 1. 准备基础文件名 (例如从 "ETN_Launcher.exe" 提取 "etn_launcher")
		#    我们去掉 .exe 后缀，并转为小写，用于开头的比较
		var base_name = EXECUTABLE_NAME.trim_suffix(".exe").to_lower()
		
		for asset in data["assets"]:
			if not asset is Dictionary:
				continue # 如果条目不是一个字典，跳过它
			var asset_name = asset.get("name", "").to_lower()
			# 调试利器：打印出每次比较的内容，让你看清发生了什么
			print("正在检查: '", asset_name, "' 是否以 '", base_name, "' 开头并以 '.exe' 结尾")
			# 2. 核心修改：使用 begins_with 和 ends_with 进行智能匹配
			if asset_name.begins_with(base_name) and asset_name.ends_with(".exe"):
				print(" ==> 匹配成功！")
				var download_url = asset.get("browser_download_url", "")
				return download_url
		
		print("循环结束，没有找到匹配的文件。")
	return ""
