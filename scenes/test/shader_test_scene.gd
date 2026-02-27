extends Control

@onready var highlight_overlay = $TestContainer/HighlightTest/CardContainer/HighlightOverlay
@onready var transition_overlay = $TransitionOverlay
@onready var transition_button = $TestContainer/TransitionTest/DemoButton
@onready var card_container = $TestContainer/HighlightTest/CardContainer

func _ready():
 #连接高亮测试的鼠标事件
 card_container.mouse_entered.connect(_on_card_mouse_entered)
 card_container.mouse_exited.connect(_on_card_mouse_exited)
 
 #连接过渡动画按钮
 transition_button.pressed.connect(_on_transition_button_pressed)

func _on_card_mouse_entered():
 #显示高亮效果
 highlight_overlay.visible = true
 
 #可选：添加Tween动画让效果更平滑
 var tween = create_tween()
 tween.tween_property(
 highlight_overlay.material,
 "shader_parameter/glow_intensity",
1.5,
0.2
 )

func _on_card_mouse_exited():
 #隐藏高亮效果
 var tween = create_tween()
 tween.tween_property(
 highlight_overlay.material,
 "shader_parameter/glow_intensity",
0.0,
0.2
 )
 await tween.finished
 highlight_overlay.visible = false

func _on_transition_button_pressed():
 #禁用按钮防止重复点击
 transition_button.disabled = true
 
 #显示过渡层
 transition_overlay.visible = true
 
 #阶段1：从清晰到模糊（0.5秒）
 var tween = create_tween()
 tween.tween_method(
 _set_blur_amount,
0.0,
8.0,
0.5
 )
 
 await tween.finished
 
 #模拟加载等待
 await get_tree().create_timer(0.5).timeout
 
 #阶段2：从模糊到清晰（0.5秒）
 tween = create_tween()
 tween.tween_method(
 _set_blur_amount,
8.0,
0.0,
0.5
 )
 
 await tween.finished
 
 #隐藏过渡层
 transition_overlay.visible = false
 
 #重新启用按钮
 transition_button.disabled = false

func _set_blur_amount(value: float):
 transition_overlay.material.set_shader_parameter("blur_amount", value)
