extends Control

@onready var transition_overlay = $TransitionOverlay
@onready var transition_button = $TestContainer/TransitionTest/DemoButton
@onready var card = $TestContainer/HighlightTest/CardContainer/Card
@onready var panel = $TestContainer/HighlightTest/CardContainer/Card/Panel
@onready var highlight_container = $TestContainer/HighlightTest
@onready var card_container: Control = $TestContainer/HighlightTest/CardContainer

func _ready():
	#初始化 Panel为透明
	panel.modulate.a =0.0
	
	#连接高亮测试的鼠标事件（使用父节点避免被Panel阻挡）
	card_container.mouse_entered.connect(_on_card_mouse_entered)
	card_container.mouse_exited.connect(_on_card_mouse_exited)
	
	#连接过渡动画按钮
	transition_button.pressed.connect(_on_transition_button_pressed)

func _on_card_mouse_entered():
	#添加Tween动画：边框显示 +图片缩小
	var tween = create_tween()
	
	# Panel透明度0 ->1
	tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.1
	)
	
	#同时 Card缩小到0.95
	tween.parallel().tween_property(
		card,
		"scale",
		Vector2(0.95,0.95),
		0.1
	)

func _on_card_mouse_exited():
	#隐藏高亮效果
	var tween = create_tween()
	
	# Panel透明度1 ->0
	tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.15
	)
	
	#图片恢复原始大小
	tween.parallel().tween_property(
		card,
		"scale",
		Vector2(1.0,1.0),
		0.15
	)

func _on_transition_button_pressed():
	#禁用按钮防止重复点击
	transition_button.disabled = true
	
	#显示过渡层
	transition_overlay.visible = true
	
	#阶段1：从清晰到模糊（0.5秒）
	var tween = create_tween()
	tween.tween_property(
		transition_overlay.material,
		"shader_parameter/blur_amount",
		7.0,
		0.5
	)
	
	await tween.finished
	
	#模拟加载等待
	await get_tree().create_timer(2).timeout
	
	#阶段2：从模糊到清晰（0.5秒）
	tween = create_tween()
	tween.tween_property(
		transition_overlay.material,
		"shader_parameter/blur_amount",
		0.0,
		0.5
	)
	
	await tween.finished
	
	#隐藏过渡层
	transition_overlay.visible = false
	
	#重新启用按钮
	transition_button.disabled = false
