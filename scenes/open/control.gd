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
	#var file_path = "res://assets/docs/version_introduction.txt"
	
	# 2. 调用我们自己编写的读取函数
	#var file_content = read_text_from_file(file_path)
	var file_content="ETN Launcher v1.0.0
这里只显示大更新，如果需要查看补丁版本，请前往仓库。
构建日期2025.12.2
启动器统一版本号1.0.0.x
内置游戏版本号0.0.0.0

✨ 新功能
现在所有的按钮功能已实装
设置菜单现在可以调整音乐声音大小
设置菜单可以更换启动音乐（无记忆功能）
设置菜单可以修复游戏
关于菜单新增描述和链接
启动游戏可以查看游戏开发动态
检查更新可以检查启动器和游戏包体更新
检查更新可以下载最新版本

🐞 修复和优化
⌨️ UI
新增窗口系统，交互更友善
启动动画增加一句描述
主菜单实现图片渐变效果
开始游戏按钮背景现在不能被选中
主菜单左上角新增版本信息
略微调整了按钮和菜单的位置
退出游戏新增提示语

🖥️ 显示
调整开始游戏按钮背景颜色和透明度
调整了按钮内部字体大小
优化字体显示效果，提升采样等级，并为字体增加描边，可读性大大提升
修改整个游戏显示模式，提升清晰度
修改抗锯齿模式和屏幕合成模式
支持DX12并采用Vulkan渲染
调整了部分按钮的圆角，观感更舒适
采用全屏无窗口模式启动游戏
新增着色器

🎬 动画
重写Tween动画管线
全局支持打断动画
动画测试100%无BUG 
加快了菜单动画速度
窗口支持可打断的淡入淡出效果

🛜 特性
文本支持BBCode
优化游戏包体大小，删除了无用的文件
优化了代码逻辑，减少代码长度
更换了捐赠付款码
更新了最新的捐赠名单
更新了捐赠款数和用途
修复了数不清的BUG
（注意 本版本未提供英文公告）

💡 开发初心
ETN 项目立项于 2025年6月11日。  
我致力于寻找回我高中的三年时光，
谨以此作纪念我的高中三年。
同时，感谢各位朋友的大力支持！
"
	
	
	## 3. 检查内容是否成功读取
	#if file_content != "null":
		## 成功！现在 file_content 变量包含了文件的全部文本
		#print("文件读取成功！")
		## 您可以把它赋给任何其他变量，比如一个 Label 的 text 属性
		## $MyLabel.text = file_content
	#else:
		## 失败！文件不存在或无法读取
		#print("读取文件失败：", file_path)

	
	
	if meta=="launcher":
		var alarm="该版本更新公告"
		
		var buttoon_text:Array[String]=["确定"]
		WindowsManager.show_dialog(alarm,file_content,buttoon_text)
	if meta=="ben_ti":
		WindowsManager.version_check(2)
	pass # Replace with function body.


# 一个健壮、可复用的文件读取函数
#func read_text_from_file(path: String) -> String:
	## 1. 直接尝试打开文件。FileAccess.open 足够智能，可以访问 .pck 包内部。
	#var file = FileAccess.open(path, FileAccess.READ)
	#
	## 2. 检查文件是否成功打开。这是在导出后唯一可靠的检查方法。
	## 如果路径在 .pck 包中不存在，file 会是 null。
	#if file == null:
		## get_open_error() 会返回一个错误码，告诉你为什么失败了。
		## 常见的错误是 ERR_FILE_NOT_FOUND (文件未找到)。
		#printerr("错误：无法打开文件 '%s'。错误码: %s" % [path, FileAccess.get_open_error()])
		#return "null"  # 或者返回空字符串 ""，取决于你的逻辑需求
	## 3. 读取内容 (这部分和您原来的一样)
	#var content = file.get_as_text()
	#
	## 4. **至关重要**：确保关闭文件！
	## 在老版本中，如果忘记 close()，可能会导致后续无法再次读取该文件。
	#file.close()
	#
	#return content
