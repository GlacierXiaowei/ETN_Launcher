extends Node
class_name UpdatePolicy

var game_name : String
var min_supported_version: String
var target_version: String
var target_patch : int
##这个变量由更新管理器处理
var force_update: bool
##会被update_checker修改
var force_full_package: bool
var full_package: Dictionary
##注意 这个成功获取了 整个数组
var patches: Array


func _init(data: Dictionary = {}):
	game_name = data.get("game_name","")
	min_supported_version = data.get("min_supported_version", "")
	target_version = data.get("target_version", "")
	target_patch = data.get("target_patch", 0)
	force_update = data.get("force_update", false)
	force_full_package = data.get("force_full_package", false)
	full_package = data.get("full_package", {})
	patches = data.get("patches", [])
