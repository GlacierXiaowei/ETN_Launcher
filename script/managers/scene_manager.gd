extends Node

var current_scene: Node = null

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func switch_scene(scene_path: String) -> void:
	call_deferred("_switch_scene",scene_path)


func get_current_scene() -> Node:
	return current_scene

func _switch_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return
	 
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = new_scene
