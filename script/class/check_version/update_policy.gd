extends Node
class_name UpdatePolicy

var game_name : String
var min_supported_version: String
var target_version: String
var target_patch : int
##这个变量由更新管理器处理
var force_update: bool
##会被 update_checker 修改
var force_full_package: bool
var full_package: Dictionary
##注意 这个成功获取了 整个数组
var patches: Array
var update_notes: String

##由versionutils传入错误信息
var err_notes : String = "未获取到有效错误原因，推测为程序bug。可尝试更换网络稍后重试😁"

func _init(data: Dictionary = {}):
	game_name = data.get("game_name","")
	min_supported_version = data.get("min_supported_version", "")
	target_version = data.get("target_version", "")
	target_patch = data.get("target_patch", 0)
	force_update = data.get("force_update", false)
	force_full_package = data.get("force_full_package", false)
	full_package = data.get("full_package", {})
	patches = data.get("patches", [])
	update_notes = data.get("update_notes", "")
