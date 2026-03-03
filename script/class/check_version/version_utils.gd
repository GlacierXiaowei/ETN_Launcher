extends Node
##已设置为全局单例

# GitHub 仓库信息
const GITHUB_OWNER = "GlacierXiaowei"
const VERSION_FILE_NAME = "cloud_version.json"

# 代理配置
var http_proxy = ""
var https_proxy = ""

# 测试用：使用本地mock文件
var use_mock_cloud_version : bool = true
var mock_cloud_version_path : String = "res://data/mock_cloud_version.json"


func _ready() -> void:
	http_proxy = OS.get_environment("http_proxy")
	https_proxy = OS.get_environment("https_proxy")
	
	if http_proxy.is_empty():
		http_proxy = OS.get_environment("HTTP_PROXY")
	if https_proxy.is_empty():
		https_proxy = OS.get_environment("HTTPS_PROXY")


func version_to_int(version: String) -> int:
	var parts = version.split(".")
	var result = 0
	for i in range(parts.size()):
		var num = parts[i].to_int()
		result = result * 10 + num
	return result

func int_to_version(num: int, part_count: int = 4) -> String:
	var parts = []
	var temp = num
	while parts.size() < part_count:
		parts.push_front(str(temp % 10))
		temp /= 10
		if temp == 0 and parts.size() >= 2:
			break
	while parts.size() < part_count:
		parts.push_front("0")
	return parts.join(".")

##从 GitHub 获取服务器更新策略
##repo: GitHub 仓库名，如 "ETN_Farm"
func get_update_policy(repo: String) -> UpdatePolicy:
	# 测试模式：从本地文件读取
	if use_mock_cloud_version:
		return _get_mock_update_policy(repo)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var download_url = "https://github.com/%s/%s/releases/latest/download/%s" % [GITHUB_OWNER, repo, VERSION_FILE_NAME]
	
	http_request.timeout = 4
	
	var headers = PackedStringArray([
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
	])
	
	if not https_proxy.is_empty():
		http_request.set_proxy(https_proxy)
	elif not http_proxy.is_empty():
		http_request.set_proxy(http_proxy)
	
	var max_retries = 3
	var retry_count = 0
	var last_response_code = 0
	
	while retry_count < max_retries:
		if retry_count > 0:
			await get_tree().create_timer(1.0).timeout
		
		var error = http_request.request(download_url, headers)
		if error != OK:
			push_error("[VersionUtils] Failed to request: " + download_url + " error: " + str(error))
			retry_count += 1
			continue
		
		var response = await http_request.request_completed
		var response_code = response[1]
		
		if response_code == 200:
			var body = response[3].get_string_from_utf8()
			remove_child(http_request)
			http_request.queue_free()
			
			var parse_result = JSON.parse_string(body)
			if parse_result == null:
				push_error("[VersionUtils] Failed to parse version JSON")
				return UpdatePolicy.new()
			
			return UpdatePolicy.new(parse_result)
		elif response_code == 0:
			retry_count += 1
			continue
		else:
			push_error("[VersionUtils] Download failed with code: " + str(response_code))
			last_response_code = response_code
			retry_count += 1
			continue
	
	remove_child(http_request)
	http_request.queue_free()
	push_error("[VersionUtils] All retries failed, last response code: " + str(last_response_code))
	return UpdatePolicy.new()

##从本地文件获取模拟的服务器更新策略（用于测试）
func _get_mock_update_policy(_repo: String) -> UpdatePolicy:
	var file_path = mock_cloud_version_path
	if not FileAccess.file_exists(file_path):
		push_error("[VersionUtils] Mock file not found: " + file_path)
		return UpdatePolicy.new()
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[VersionUtils] Failed to open mock file: " + file_path)
		return UpdatePolicy.new()
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("[VersionUtils] Failed to parse mock JSON")
		return UpdatePolicy.new()
	
	print("[VersionUtils] Using mock cloud version from: " + file_path)
	return UpdatePolicy.new(json.data)

##从本地获取版本信息
##path: version.json 文件路径，默认使用用户目录下的版本文件
func get_version_info(path: String = "") -> VersionInfo:
	if path == "":
		var appdata = OS.get_environment("APPDATA")
		var user_path = appdata.path_join("ETN_Farm")
		path = user_path.path_join("version.json")
	
	if not FileAccess.file_exists(path):
		push_error("[VersionUtils] version.json not found at: " + path)
		return VersionInfo.new()
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[VersionUtils] Failed to open: " + path)
		return VersionInfo.new()
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("[VersionUtils] Failed to parse JSON at: " + path)
		return VersionInfo.new()
	
	return VersionInfo.new(json.data)


##清空下载文件夹
func clear_folder(path : String) -> bool:
	if path == "" or path.is_empty():
		push_error("[VersionUtils] clear_folder: path is empty")
		return false
	
	if not DirAccess.dir_exists_absolute(path):
		var d = DirAccess.open("user://")
		if d == null:
			push_error("[VersionUtils] clear_folder: Failed to open user://")
			return false
		var err = d.make_dir_recursive(path)
		if err != OK:
			push_error("[VersionUtils] clear_folder: Failed to create directory")
			return false
		return true
	
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("[VersionUtils] clear_folder: Failed to open directory")
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path.path_join(file_name)
			var err = dir.remove(full_path)
			if err != OK:
				push_error("[VersionUtils] clear_folder: Failed to delete file: " + full_path)
				dir.list_dir_end()
				return false
		file_name = dir.get_next()
	dir.list_dir_end()
	return true
