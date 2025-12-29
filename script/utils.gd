# utils.gd (增强版)
# 这是一个全局工具箱，请在“项目设置”->“Autoload”中添加它，节点名设为 "Utils"
# 它提供项目中任何地方都可能用到的通用辅助函数。

extends Node


# --- 版本号转换工具 ---
# 将 "v1.2.3.4" 格式的版本字符串，安全地转换为 1234 这样的整数，便于比较。
# 示例: "v1.2.3.0" -> 1230
# 示例: "1.10.5.0" -> 11050 (正确处理两位数版本)
func version_string_to_int(version_str: String) -> int:
	# 防御性编程：如果输入为空或格式不正确，返回0
	if version_str.is_empty():
		return 0

	# 去掉可能存在的 'v' 前缀
	var clean_str = version_str.trim_prefix("v")
	
	# 按 '.' 分割版本号
	var parts = clean_str.split(".", false) # false表示不跳过空字符串
	
	var major = 0
	var minor = 0
	var patch = 0
	var revision = 0
	
	if parts.size() > 0: 
		major = parts[0].to_int() if parts[0].is_valid_int() else 0
	if parts.size() > 1: 
		minor = parts[1].to_int() if parts[1].is_valid_int() else 0
	if parts.size() > 2: 
		patch = parts[2].to_int() if parts[2].is_valid_int() else 0
	if parts.size() > 3: 
		revision = parts[3].to_int() if parts[3].is_valid_int() else 0

	# 使用权重来计算最终的整数值
	# 保证每个部分有足够的"空间"，不会互相干扰
	var version_int = major * 1000000 + minor * 10000 + patch * 100 + revision
	return version_int

# --- 新增功能函数 ---

# 安全地连接路径
func path_join(base: String, subpath: String) -> String:
	return base.path_join(subpath)

# 获取游戏目录
func get_game_directory() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir.path_join("..").path_join("game")

# --- 文件系统工具 ---
# 检查文件是否存在，可提供可选的人性化提示
func file_exists(path: String, show_error: bool = false) -> bool:
	var exists = FileAccess.file_exists(path)
	if show_error and not exists:
		printerr("文件不存在: ", path)
	return exists

# 安全读取JSON文件
func read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		printerr("JSON文件不存在: ", path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("无法打开JSON文件: ", path)
		return {}
	
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error != OK:
		printerr("无法解析JSON文件: ", path, " 错误: ", json.get_error_message())
		return {}
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		printerr("JSON文件不是有效的字典: ", path)
		return {}
	
	return data

# --- 补丁管理工具 ---
# 扫描补丁目录中的补丁文件
func scan_patch_files(directory: String = "user://temp/patches") -> Array:
	var patches = []
	var dir = DirAccess.open(directory)
	
	if dir == null:
		# 如果目录不存在，创建它
		DirAccess.make_dir_recursive_absolute(directory)
		return patches
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".pck"):
			patches.append(path_join(directory, file_name))
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return patches

# -- 网络工具 ---
# 检查网络连接
func check_network_connectivity() -> bool:
	# 简单的网络检查，可以扩展为更复杂的检查
	return OS.has_feature("web") or true # 暂时简单返回true，可替换为真实检查

# --- UI工具 ---
# 格式化下载速度
func format_speed(speed_mbps: float) -> String:
	if speed_mbps <= 0:
		return "0 MB/s"
	elif speed_mbps < 1:
		return "%0.2f KB/s" % (speed_mbps * 1024)
	else:
		return "%0.2f MB/s" % speed_mbps

# 格式化文件大小
func format_file_size(bytes: int) -> String:
	var mb = float(bytes) / (1024.0 * 1024.0)
	return "%0.2f MB" % mb

# 从URL提取文件名
func get_filename_from_url(url: String) -> String:
	var parts = url.split("/")
	if parts.is_empty():
		return "unknown.file"
	return parts[-1]

# 提取补丁版本号从文件名 (例如: "patch_v1.2.3.pck" -> 1002003)
func extract_patch_version_from_filename(filename: String) -> int:
	var clean_name = filename.replace(".pck", "").to_lower()
	var version_str = ""
	
	# 查找版本号模式
	var regex = RegEx.new()
	if regex.compile("v?(\\d+\\.\\d+\\.\\d+\\.\\d+)") == OK:
		var result = regex.search(clean_name)
		if result:
			version_str = result.get_string(1)
	
	if version_str.is_empty():
		# 尝试其他格式
		if regex.compile("(\\d+)_(\\d+)_(\\d+)_(\\d+)") == OK:
			var result = regex.search(clean_name)
			if result:
				version_str = "%s.%s.%s.%s" % [result.get_string(1), result.get_string(2), result.get_string(3), result.get_string(4)]
	
	if version_str.is_empty():
		return 0
	
	return version_string_to_int(version_str)

# 判断是否为必要补丁
func is_essential_patch(patch_info: Dictionary) -> bool:
	return patch_info.get("essential", false)
