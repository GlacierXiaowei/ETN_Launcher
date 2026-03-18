extends Control

@onready var background_blur = $CanvasLayer/BackgroundBlur
@onready var loading_player = $CanvasLayer/SmallLodingPlayer

var play_video: bool = true  # 是否播放视频

signal blur_animation_completed      # 第一段：模糊到8.0完成
signal transition_completed          # 第三段：恢复清晰完成

func _ready() -> void:
	await get_tree().process_frame
	# 初始化模糊参数
	_update_rect_size()
	
	# 连接 SceneManager 的加载完成信号
	if SceneManager:
		SceneManager.scene_load_completed.connect(_on_scene_load_completed)
	
	# 执行第一段动画：模糊到8.0
	await _perform_blur_animation()

func _process(_delta: float) -> void:
	# 持续更新shader参数以适应屏幕尺寸
	_update_rect_size()

func _update_rect_size() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	background_blur.material.set_shader_parameter("rect_size_px", screen_size)

func _perform_blur_animation() -> void:
	background_blur.material.set_shader_parameter("blur_amount", 0.0)
	
	# 只在完整模式下播放视频
	if play_video:
		loading_player.visible = true
		if not loading_player.is_playing():
			loading_player.play()
	
	var tween = create_tween()
	tween.tween_property(background_blur.material, "shader_parameter/blur_amount", 8.0, 0.5)
	await tween.finished
	
	emit_signal("blur_animation_completed")

func _on_scene_load_completed(_loaded_scene: Node) -> void:
	var tween = create_tween()
	tween.tween_property(background_blur.material, "shader_parameter/blur_amount", 0.0, 0.5)
	await tween.finished
	
	# 只在完整模式下停止视频
	if play_video:
		loading_player.visible = false
		loading_player.stop()
	
	emit_signal("transition_completed")
