extends Control

@onready var _menu_bg_animation = preload("res://scenes/menu_bg_animation.tscn")
var _version_judge_var=2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label_open.modulate.a=0
	$bei_jin.modulate.a=255
	$open_button.hide()
	
	$open_image_2.modulate.a=0
	$open_image_3.modulate.a=0
	$Open_Ani_Player_1.play("open_animation_1")
	
	#1 代表 检查通过 2代表正在检查 0代表版本需要更新
	_version_judge()
	await $Open_Ani_Player_1.animation_finished
	$Open_Ani_Player_2.play("open_animation_2")
	#因为这里可能只会打包成一个软件 然后 这里的话 就是根据返回值 弹弹窗告知
	#我们还要准备一个提示框
	#需要为release 版本集成 下载器和安装器 #同时集成到 启动器中 
	#为之后 游戏主体更新做准备
	await $Open_Ani_Player_2.animation_finished
	await _version_judge()
	if ( _version_judge_var==1  ):
		#很诡异 他们了可以调用所有的动画
		$open_image_2.modulate.a=0
		$Open_Ani_Player_2.play("open_animation_3")
		$open_image_3.z_index=20
		$bei_jin.z_index=15
		
		await get_tree().create_timer(1.95).timeout 
		$Open_Ani_Player_2.pause()
		
		var tween_label_open_in = $".".create_tween()
		var tween_label_open_out = $".".create_tween()
		
		tween_label_open_in.tween_property($Label_open,"modulate:a",1.0,0.5)
		$open_button.show()
		await $open_button.pressed
		
		tween_label_open_out.tween_property($Label_open,"modulate.a",0.0,0.25)
		$Open_Ani_Player_2.play()
		
		
		
		var _menu_bg_animation_instance=_menu_bg_animation.instantiate()
		_menu_bg_animation_instance.z_index=0
		add_child(_menu_bg_animation_instance)
		
		$Label_open.queue_free()
		$open_button.queue_free()
		$open_image_1.queue_free()
		$open_image_2.queue_free()
		$Open_Ani_Player_1.queue_free()
		
		await $Open_Ani_Player_2.animation_finished
		
		pass
	else:
		pass
	 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _version_judge():
	#1 代表 检查通过 2代表正在检查 0代表版本需要更新
	_version_judge_var=1
