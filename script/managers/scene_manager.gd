extends Node

var current_scene: Node = null
var original_scene: Node = null  # 保存原始场景引用
var loading_scene_path = "res://scenes/loading/loading_scene.tscn"
var target_scene_to_load = ""
var current_loading_mode = ""
var is_loading = false

# 加载模式常量
const LOADING_MODE_HARD = "hard"           # 硬切加载（黑屏）
const LOADING_MODE_BLUR = "blur"           # 背景模糊
const LOADING_MODE_FULL = "full"           # 完整加载（模糊+动画）

# 信号
signal scene_switch_started(scene_path)
signal scene_switch_completed(scene_path)
signal scene_switch_failed(error_message)
signal scene_load_completed(loaded_scene)  # 新增：场景加载完成信号

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func switch_scene(scene_path: String) -> void:
	call_deferred("_switch_scene", scene_path)

func switch_scene_with_loading(scene_path: String, mode: String = LOADING_MODE_FULL) -> void:
	if is_loading:
		push_warning("Scene switch already in progress")
		return
	
	target_scene_to_load = scene_path
	current_loading_mode = mode
	is_loading = true
	emit_signal("scene_switch_started", scene_path)
	call_deferred("_switch_to_loading_scene")

func get_current_scene() -> Node:
	return current_scene

func is_scene_loading() -> bool:
	return is_loading

func _switch_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		emit_signal("scene_switch_failed", "Scene not found: " + scene_path)
		is_loading = false
		return
	 
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = new_scene
	is_loading = false
	emit_signal("scene_switch_completed", scene_path)

func _switch_to_loading_scene() -> void:
	match current_loading_mode:
		LOADING_MODE_HARD:
			await _load_and_switch(target_scene_to_load)
			return
		LOADING_MODE_BLUR, _:
			if not ResourceLoader.exists(loading_scene_path):
				push_error("Loading scene not found: " + loading_scene_path)
				emit_signal("scene_switch_failed", "Loading scene not found: " + loading_scene_path)
				is_loading = false
				return
			
			var loading_scene = load(loading_scene_path).instantiate()
			
			# BLUR模式不播放视频
			if current_loading_mode == LOADING_MODE_BLUR:
				loading_scene.play_video = false
			
			get_tree().root.add_child(loading_scene)
			
			original_scene = current_scene
			current_scene = loading_scene
			
			loading_scene.blur_animation_completed.connect(_on_blur_animation_completed)
			loading_scene.transition_completed.connect(_on_transition_completed)

var _loaded_new_scene: Node = null

func _load_target_scene_async(target_scene_path: String) -> void:
	if not ResourceLoader.exists(target_scene_path):
		push_error("Target scene not found: " + target_scene_path)
		emit_signal("scene_switch_failed", "Target scene not found: " + target_scene_path)
		is_loading = false
		return
	
	# 实际加载场景
	var new_scene = load(target_scene_path).instantiate()
	_loaded_new_scene = new_scene
	
	# 添加新场景到根节点（新场景在底层，loading_scene 在顶层播放恢复动画）
	get_tree().root.add_child(new_scene)
	
	# 发出场景加载完成信号
	emit_signal("scene_load_completed", new_scene)

func _switch_to_loaded_scene(_loaded_scene: Node) -> void:
	for i in range(get_tree().root.get_child_count()):
		var child = get_tree().root.get_child(i)
		if child.name == "LoadingScene":
			child.queue_free()
	
	current_scene = _loaded_new_scene
	_loaded_new_scene = null
	var completed_path = target_scene_to_load
	target_scene_to_load = ""
	current_loading_mode = ""
	is_loading = false
	emit_signal("scene_switch_completed", completed_path)

func _load_and_switch(target_scene_path: String) -> void:
	if not ResourceLoader.exists(target_scene_path):
		push_error("Target scene not found: " + target_scene_path)
		emit_signal("scene_switch_failed", "Target scene not found: " + target_scene_path)
		is_loading = false
		return
	
	await get_tree().create_timer(0.5).timeout
	
	var new_scene = load(target_scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	
	for i in range(get_tree().root.get_child_count()):
		var child = get_tree().root.get_child(i)
		if child.name == "LoadingScene":
			child.queue_free()
	
	if original_scene:
		original_scene.queue_free()
		original_scene = null
	
	if current_scene and current_scene != new_scene:
		current_scene.queue_free()
	
	current_scene = new_scene
	target_scene_to_load = ""
	current_loading_mode = ""
	is_loading = false
	emit_signal("scene_switch_completed", target_scene_path)

func _on_blur_animation_completed() -> void:
	# 清理原始场景（在加载新场景之前）
	if original_scene:
		original_scene.queue_free()
		original_scene = null
	
	# 第一段动画完成，开始加载新场景
	_load_target_scene_async(target_scene_to_load)

func _on_transition_completed() -> void:
	# 第三段动画完成，清理临时节点
	_switch_to_loaded_scene(null)
