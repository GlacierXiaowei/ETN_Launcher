extends Node
##已设置为全局单例

# GitHub 仓库信息
const GITHUB_OWNER = "GlacierXiaowei"
const VERSION_FILE_NAME = "cloud_version.json"

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
func get_update_policy(repo: String = "ETN_Farm") -> UpdatePolicy:
	# 1. 使用 GitHub API 获取 latest release 的 tag
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var api_url = "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_OWNER, repo]
	var error = http_request.request(api_url)
	
	if error != OK:
		push_error("[VersionUtils] Failed to request GitHub API: " + api_url)
		remove_child(http_request)
		http_request.free()
		return UpdatePolicy.new()
	
	var response = await http_request.request_completed
	var response_code = response[1]
	
	if response_code != 200:
		push_error("[VersionUtils] GitHub API returned code: " + str(response_code))
		remove_child(http_request)
		http_request.free()
		return UpdatePolicy.new()
	
	var body = response[3].get_string_from_utf8()
	var release_data = JSON.parse_string(body)
	
	remove_child(http_request)
	http_request.free()
	
	if release_data == null:
		push_error("[VersionUtils] Failed to parse release data")
		return UpdatePolicy.new()
	
	# 获取 tag 名称
	var tag = release_data.get("tag_name", "")
	if tag == "":
		push_error("[VersionUtils] No tag_name in release data")
		return UpdatePolicy.new()
	
	# 2. 下载 JSON 文件
	var download_url = "https://github.com/%s/%s/releases/download/%s/%s" % [GITHUB_OWNER, repo, tag, VERSION_FILE_NAME]
	
	var download_request = HTTPRequest.new()
	add_child(download_request)
	
	error = download_request.request(download_url)
	if error != OK:
		push_error("[VersionUtils] Failed to download: " + download_url)
		remove_child(download_request)
		download_request.free()
		return UpdatePolicy.new()
	
	var download_response = await download_request.request_completed
	var download_response_code = download_response[1]
	var download_body = download_response[3]
	
	remove_child(download_request)
	download_request.free()
	
	if download_response_code != 200:
		push_error("[VersionUtils] Download failed with code: " + str(download_response_code))
		return UpdatePolicy.new()
	
	# 3. 解析 JSON
	var parse_result = JSON.parse_string(download_body.get_string_from_utf8())
	if parse_result == null:
		push_error("[VersionUtils] Failed to parse version JSON")
		return UpdatePolicy.new()
	
	print("[VersionUtils] Downloaded version file, tag: " + tag)
	return UpdatePolicy.new(parse_result)

##从本地获取版本信息
##path: version.json 文件路径，默认使用用户目录下的版本文件
func get_version_info(path: String = "") -> VersionInfo:
	# 默认路径
	if path == "":
		var appdata = OS.get_environment("APPDATA")
		var user_path = appdata.path_join("ETN_Farm")
		path = user_path.path_join("version.json")
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path):
		push_error("[VersionUtils] version.json not found at: " + path)
		return VersionInfo.new()
	
	# 读取并解析
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
	
	print("[VersionUtils] Loaded version info from: " + path)
	return VersionInfo.new(json.data)
