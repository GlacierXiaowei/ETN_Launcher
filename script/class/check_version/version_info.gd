extends Node
class_name VersionInfo


var base_version: String
var base_patch_max: int
var equal_version: String
var game_name: String
var current_patch: int



func _init(data: Dictionary = {}):
	base_version = data.get("base_version", "")
	base_patch_max = data.get("base_patch_max", 0)
	equal_version = data.get("equal_version", "")
	game_name = data.get("game_name", "")
	current_patch = data.get("current_patch", base_patch_max)
	
