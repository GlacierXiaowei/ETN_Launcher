extends Control

# 场景模糊覆盖层 - 直接应用于当前场景
var blur_amount: float = 0.0:
	set(value):
		blur_amount = value
		if material and material is ShaderMaterial:
			material.set_shader_parameter("blur_amount", blur_amount)

@onready var loading_player = $SmallLodingPlayer

func _ready() -> void:
	# 初始化模糊shader
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://assets/shaders/transition_blur.gdshader")
	self.material = shader_mat
	
	# 设置初始参数
	_update_rect_size()
	resized.connect(_update_rect_size)
	
	# 初始隐藏
	visible = false
	loading_player.visible = false

func _update_rect_size() -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter("rect_size_px", self.size)

func start_blur_transition() -> void:
	# 显示模糊覆盖层
	visible = true
	blur_amount = 0.0
	
	# 播放模糊动画：清晰 -> 模糊
	var tween = create_tween()
	tween.tween_property(self, "blur_amount", 8.0, 0.5)
	await tween.finished
	
	# 显示加载动画
	loading_player.visible = true
	if not loading_player.is_playing():
		loading_player.play()

func end_blur_transition() -> void:
	# 隐藏加载动画
	loading_player.visible = false
	loading_player.stop()
	
	# 播放恢复动画：模糊 -> 清晰
	var tween = create_tween()
	tween.tween_property(self, "blur_amount", 0.0, 0.5)
	await tween.finished
	
	# 隐藏模糊覆盖层
	visible = false