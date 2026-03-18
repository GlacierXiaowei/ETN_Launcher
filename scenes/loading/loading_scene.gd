extends Control

@onready var background_blur = $CanvasLayer/BackgroundBlur
@onready var black_background = $CanvasLayer/BlackBackground
@onready var loading_player = $CanvasLayer/SmallLodingPlayer

enum LoadingMode { FULL, BLUR, BLACK }
var loading_mode: LoadingMode = LoadingMode.FULL

signal blur_animation_completed
signal transition_completed

func _ready() -> void:
	await get_tree().process_frame
	_update_rect_size()
	
	if SceneManager:
		SceneManager.scene_load_completed.connect(_on_scene_load_completed)
	
	match loading_mode:
		LoadingMode.BLACK:
			await _perform_black_animation()
		_:
			await _perform_blur_animation()

func _process(_delta: float) -> void:
	# 持续更新shader参数以适应屏幕尺寸
	_update_rect_size()

func _update_rect_size() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	background_blur.material.set_shader_parameter("rect_size_px", screen_size)

func _perform_blur_animation() -> void:
	background_blur.material.set_shader_parameter("blur_amount", 0.0)
	black_background.modulate.a = 0.0
	
	if loading_mode == LoadingMode.FULL:
		loading_player.visible = true
		if not loading_player.is_playing():
			loading_player.play()
	
	var tween = create_tween()
	tween.tween_property(background_blur.material, "shader_parameter/blur_amount", 8.0, 0.5)
	await tween.finished
	
	emit_signal("blur_animation_completed")

func _perform_black_animation() -> void:
	black_background.modulate.a = 0.0
	background_blur.visible = false
	loading_player.visible = false
	
	var tween = create_tween()
	tween.tween_property(black_background, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	emit_signal("blur_animation_completed")

func _on_scene_load_completed(_loaded_scene: Node) -> void:
	match loading_mode:
		LoadingMode.BLACK:
			await _perform_black_transition()
		_:
			await _perform_blur_transition()
	
	emit_signal("transition_completed")

func _perform_blur_transition() -> void:
	var tween = create_tween()
	tween.tween_property(background_blur.material, "shader_parameter/blur_amount", 0.0, 0.5)
	await tween.finished
	
	if loading_mode == LoadingMode.FULL:
		loading_player.visible = false
		loading_player.stop()

func _perform_black_transition() -> void:
	var tween = create_tween()
	tween.tween_property(black_background, "modulate:a", 0.0, 0.3)
	await tween.finished
