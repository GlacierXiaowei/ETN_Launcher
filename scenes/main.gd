extends Control


var _version_judge_var=2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	if ( (_version_judge_var==1) and ($Open_Ani_Player_2.animation_finished) ):
		pass
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _version_judge():
	#1 代表 检查通过 2代表正在检查 0代表版本需要更新
	_version_judge_var=1
