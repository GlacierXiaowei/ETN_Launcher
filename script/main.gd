extends Control
@onready var menu_bg = preload("res://scenes/open/menu_bg.tscn")
@onready var ui = preload("res://scenes/open/ui.tscn")
var _version_judge_var=1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#加载补丁包
	$Label_open.modulate.a=0
	$bei_jin.modulate.a=255
	$open_button.hide()
	$open_image_2.modulate.a=0
	
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
		#很诡异 他们可以调用所有的动画
		print("动画3已经播放")
		$open_image_2.modulate.a=0
		$Open_Ani_Player_2.play("open_animation_3")
		
		$bei_jin.z_index=15
		
		await get_tree().create_timer(3.5).timeout 
		#$Open_Ani_Player_2.pause()
		
		$Open_Ani_Player_3.play("open_meanings_label_ani")
		$open_button.show()
		await $open_button.pressed
		
		#tween_label_open_out.tween_property($Label_open,"modulate.a",0.0,0.25)
		
		
		var menu_bg_instance=menu_bg.instantiate()
		menu_bg_instance.z_index=0
		add_child(menu_bg_instance)
		
		$Label_open.queue_free()
		$open_button.queue_free()
		$open_image_1.queue_free()
		$open_image_2.queue_free()
		$Open_Ani_Player_1.queue_free()
		$open_image_30.queue_free()
		$bei_jin.queue_free()
		var ui_instance=ui.instantiate()
		add_child(ui_instance)
		ui_instance.z_index=30

	else:
		pass
	 # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _version_judge():
	
	#1 代表 检查通过 2代表正在检查 0代表版本需要更新
	_version_judge_var=1
