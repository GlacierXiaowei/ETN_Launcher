extends Control

@onready var status_label = $VBoxContainer/StatusLabel
@onready var log_label = $LogLabel
var log_messages = []

func _ready() -> void:
	# 连接 SceneManager 信号
	SceneManager.scene_switch_started.connect(_on_scene_switch_started)
	SceneManager.scene_switch_completed.connect(_on_scene_switch_completed)
	SceneManager.scene_switch_failed.connect(_on_scene_switch_failed)
	
	# 连接按钮信号
	$VBoxContainer/HardCutButton.pressed.connect(_on_hard_cut_pressed)
	$VBoxContainer/BlurButton.pressed.connect(_on_blur_pressed)
	$VBoxContainer/BlackButton.pressed.connect(_on_black_pressed)
	$VBoxContainer/FullButton.pressed.connect(_on_full_pressed)
	$VBoxContainer/DirectButton.pressed.connect(_on_direct_pressed)
	
	add_log("测试场景已就绪")

func _on_hard_cut_pressed() -> void:
	add_log("开始硬切加载测试...")
	# 隐藏测试场景以避免CanvasLayer遮挡
	
	SceneManager.switch_scene_with_loading("res://scenes/test/return_test_scene.tscn", SceneManager.LOADING_MODE_HARD)

func _on_blur_pressed() -> void:
	add_log("开始背景模糊加载测试...")
	
	SceneManager.switch_scene_with_loading("res://scenes/test/return_test_scene.tscn", SceneManager.LOADING_MODE_BLUR)

func _on_black_pressed() -> void:
	add_log("开始黑屏加载测试...")
	
	SceneManager.switch_scene_with_loading("res://scenes/test/return_test_scene.tscn", SceneManager.LOADING_MODE_BLACK)

func _on_full_pressed() -> void:
	add_log("开始完整加载测试...")
	
	SceneManager.switch_scene_with_loading("res://scenes/test/return_test_scene.tscn", SceneManager.LOADING_MODE_FULL)

func _on_direct_pressed() -> void:
	add_log("开始直接切换测试...")
	
	SceneManager.switch_scene("res://scenes/test/return_test_scene.tscn")

func _on_scene_switch_started(scene_path: String) -> void:
	status_label.text = "当前状态：加载中..."
	add_log("场景切换开始：" + scene_path)

func _on_scene_switch_completed(scene_path: String) -> void:
	status_label.text = "当前状态：加载完成"
	add_log("场景切换完成：" + scene_path)
	# 如果返回到此场景，确保可见


func _on_scene_switch_failed(error_message: String) -> void:
	status_label.text = "当前状态：加载失败"
	add_log("场景切换失败：" + error_message)
	 

func add_log(message: String) -> void:
	var timestamp = Time.get_datetime_string_from_system(false, true).substr(11, 8)
	log_messages.append("[%s] %s" % [timestamp, message])
	
	# 只保留最后 5 条日志
	if log_messages.size() > 5:
		log_messages.pop_front()
	
	log_label.text = "日志：\n" + "\n".join(log_messages)
