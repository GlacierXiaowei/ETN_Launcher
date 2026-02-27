extends Node

var game_dir = OS.get_environment("APPDATA")
var user_path : String = game_dir.path_join("ETN_Launcher")
var dest_path = user_path.path_join("version.json")

var source_path = "res://data/version.json"

var MainScene = load("res://scenes/boot_scene/splash_screen.tscn")

func _ready() -> void:
	call_deferred("copy_version_to_user")
	call_deferred("change_scene")
	
	

func copy_version_to_user() -> void:
	if not DirAccess.dir_exists_absolute(user_path):
		var dir = DirAccess.open("user://")
		dir.make_dir_recursive(user_path)
	
	if FileAccess.file_exists(source_path):
		var source_file = FileAccess.open(source_path, FileAccess.READ)
		if source_file:
			var content = source_file.get_as_text()
			source_file.close()
			
			var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
			if dest_file:
				dest_file.store_string(content)
				dest_file.close()
				print("版本文件已复制到: ", dest_path)
			else:
				push_error("无法写入目标文件: " + dest_path)
		else:
			push_error("无法读取源文件: " + source_path)
	else:
		push_error("源文件不存在: " + source_path)


func change_scene() -> void:
	get_tree().change_scene_to_packed(MainScene)
